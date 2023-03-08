import UIKit
import WalletConnectSign
import WalletConnectUtils
import WalletConnectPairing
import WalletConnectRouter
import Web3
import CryptoSwift
import Combine

final class WalletViewController: UIViewController {

    lazy var accounts = [
        "eip155": ETHSigner.address,
        "solana": SOLSigner.address
    ]

    var sessionItems: [ActiveSessionItem] = []

    var currentProposal: Session.Proposal?
    private var publishers = [AnyCancellable]()

    var onClientConnected: (() -> Void)?

    private let walletView: WalletView = {
        WalletView()
    }()

    override func loadView() {
        view = walletView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Wallet"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack))
        walletView.scanButton.addTarget(self, action: #selector(showScanner), for: .touchUpInside)
        walletView.pasteButton.addTarget(self, action: #selector(showTextInput), for: .touchUpInside)

        walletView.tableView.dataSource = self
        walletView.tableView.delegate = self

        setUpSessions()
        setUpAuthSubscribing()
    }

    private func setUpSessions() {
        reloadSessions(Sign.instance.getSessions())
    }

    @objc
    private func showScanner() {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }

    @objc
    private func showTextInput() {
        let alert = UIAlertController.createInputAlert { [weak self] inputText in
            guard let self = self, let uri = WalletConnectURI(string: inputText) else { return }
            self.pairClient(uri: uri)
        }
        present(alert, animated: true)
    }

    @objc
    private func goBack() {
        Router.goBack()
    }

    private func showSessionProposal(_ proposal: Proposal) {
        let proposalViewController = ProposalViewController(proposal: proposal)
        proposalViewController.delegate = self
        present(proposalViewController, animated: true)
    }

    private func showSessionDetails(with session: Session) {
        let viewController = SessionDetailViewController(session: session, client: Sign.instance)
        navigationController?.present(viewController, animated: true)
    }

    private func showSessionRequest(_ request: Request) {
        let requestVC = RequestViewController(request)
        requestVC.onSign = { [unowned self] in
            do {
                let result = try Signer.sign(request: request)
                respondOnSign(request: request, response: result)
                reloadSessionDetailsIfNeeded()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        requestVC.onReject = { [unowned self] in
            respondOnReject(request: request)
            reloadSessionDetailsIfNeeded()
        }
        reloadSessionDetailsIfNeeded()
        present(requestVC, animated: true)
    }

    func reloadSessionDetailsIfNeeded() {
        if let viewController = navigationController?.presentedViewController as? SessionDetailViewController {
            viewController.reload()
        }
    }

    @MainActor
    private func respondOnSign(request: Request, response: AnyCodable) {
        print("[WALLET] Respond on Sign")
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(response))
            } catch {
                print("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func respondOnReject(request: Request) {
        print("[WALLET] Respond on Reject")
        Task {
            do {
                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .error(.init(code: 0, message: ""))
                )
            } catch {
                print("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func pairClient(uri: WalletConnectURI) {
        print("[WALLET] Pairing to: \(uri)")
        Task {
            do {
                try await Pair.instance.pair(uri: uri)
            } catch {
                print("[DAPP] Pairing connect error: \(error)")
            }
        }
    }

    @MainActor
    private func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
        print("[WALLET] Approve Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
            } catch {
                print("[DAPP] Approve Session error: \(error)")
            }
        }
    }

    @MainActor
    private func reject(proposalId: String, reason: RejectionReason) {
        print("[WALLET] Reject Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.reject(proposalId: proposalId, reason: reason)
            } catch {
                print("[DAPP] Reject Session error: \(error)")
            }
        }
    }
}

extension WalletViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessionItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! ActiveSessionCell
        cell.item = sessionItems[indexPath.row]
        return cell
    }

    @MainActor
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = sessionItems[indexPath.row]
            Task {
                do {
                    try await Sign.instance.disconnect(topic: item.topic)
                } catch {
                    print(error)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Disconnect"
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("did select row \(indexPath)")
        let itemTopic = sessionItems[indexPath.row].topic
        if let session = Sign.instance.getSessions().first(where: {$0.topic == itemTopic}) {
            showSessionDetails(with: session)
        }
    }
}

extension WalletViewController: ScannerViewControllerDelegate {

    func didScan(_ code: String) {
        guard let uri = WalletConnectURI(string: code) else { return }
        pairClient(uri: uri)
    }
}

extension WalletViewController: ProposalViewControllerDelegate {

    func didApproveSession() {
        let proposal = currentProposal!
        currentProposal = nil
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains!.compactMap { Account($0.absoluteString + ":\(self.accounts[$0.namespace]!)") })

            let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }

    func didRejectSession() {
        let proposal = currentProposal!
        currentProposal = nil
        reject(proposalId: proposal.id, reason: .userRejectedChains)
    }
}

extension WalletViewController {
    func setUpAuthSubscribing() {
        Sign.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    print("Client connected")
                    self?.onClientConnected?()
                }
            }.store(in: &publishers)

        // TODO: Adapt proposal data to be used on the view
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                print("[RESPONDER] WC: Did receive session proposal")
                self?.currentProposal = sessionProposal
                    self?.showSessionProposal(Proposal(proposal: sessionProposal)) // FIXME: Remove mock
            }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                print("[RESPONDER] WC: Did receive session request")
                self?.showSessionRequest(sessionRequest)
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigationController?.popToRootViewController(animated: true)
            }.store(in: &publishers)

        Sign.instance.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                self?.reloadSessions(sessions)
            }.store(in: &publishers)
    }

    private func getActiveSessionItem(for settledSessions: [Session]) -> [ActiveSessionItem] {
        return settledSessions.map { session -> ActiveSessionItem in
            let app = session.peer
            return ActiveSessionItem(
                dappName: app.name ,
                dappURL: app.url ,
                iconURL: app.icons.first ?? "",
                topic: session.topic)
        }
    }

    private func reloadSessions(_ sessions: [Session]) {
        sessionItems = getActiveSessionItem(for: sessions)
        walletView.tableView.reloadData()
    }
}
