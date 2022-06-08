import UIKit
import WalletConnectSign
import WalletConnectUtils
import Web3
import CryptoSwift
import Combine

final class WalletViewController: UIViewController {
    lazy  var account = Signer.privateKey.address.hex(eip55: true)
    var sessionItems: [ActiveSessionItem] = []
    var currentProposal: Session.Proposal?
    var onClientConnected: (()->())?
    private var publishers = [AnyCancellable]()

    private let walletView: WalletView = {
        WalletView()
    }()
    
    override func loadView() {
        view = walletView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Wallet"
        walletView.scanButton.addTarget(self, action: #selector(showScanner), for: .touchUpInside)
        walletView.pasteButton.addTarget(self, action: #selector(showTextInput), for: .touchUpInside)
        
        walletView.tableView.dataSource = self
        walletView.tableView.delegate = self
        let settledSessions = Sign.instance.getSessions()
        sessionItems = getActiveSessionItem(for: settledSessions)
        setUpAuthSubscribing()
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
            self?.pairClient(uri: inputText)
        }
        present(alert, animated: true)
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
            let result = Signer.signEth(request: request)
            let response = JSONRPCResponse<AnyCodable>(id: request.id, result: result)
            respondOnSign(request: request, response: response)
            reloadSessionDetailsIfNeeded()
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
    
    private func respondOnSign(request: Request, response: JSONRPCResponse<AnyCodable>) {
        print("[CONTROLLER] Respond on Sign")
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, response: .response(response))
            } catch {
                print("[NON-CONTROLLER] Respond Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func respondOnReject(request: Request) {
        print("[CONTROLLER] Respond on Reject")
        Task {
            do {
                try await Sign.instance.respond(
                    topic: request.topic,
                    response: .error(JSONRPCErrorResponse(
                        id: request.id,
                        error: JSONRPCErrorResponse.Error(code: 0, message: ""))
                    )
                )
            } catch {
                print("[NON-CONTROLLER] Respond Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func pairClient(uri: String) {
        print("[CONTROLLER] Pairing to: \(uri)")
        Task {
            do {
                try await Sign.instance.pair(uri: uri)
            } catch {
                print("[NON-CONTROLLER] Pairing connect error: \(error)")
            }
        }
    }
    
    private func approve(proposalId: String, namespaces: [String : SessionNamespace]) {
        print("[CONTROLLER] Approve Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
            } catch {
                print("[NON-CONTROLLER] Approve Session error: \(error)")
            }
        }
    }
    
    private func reject(proposalId: String, reason: RejectionReason) {
        print("[CONTROLLER] Reject Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.reject(proposalId: proposalId, reason: reason)
            } catch {
                print("[NON-CONTROLLER] Reject Session error: \(error)")
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = sessionItems[indexPath.row]
            Task {
                do {
                    try await Sign.instance.disconnect(topic: item.topic, reason: Reason(code: 0, message: "disconnect"))
                    DispatchQueue.main.async { [weak self] in
                        self?.sessionItems.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
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
        pairClient(uri: code)
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
            let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(account)") } )
            
            let extensions: [SessionNamespace.Extension]? = proposalNamespace.extensions?.map { element in
                let accounts = Set(element.chains.compactMap { Account($0.absoluteString + ":\(account)") } )
                return SessionNamespace.Extension(accounts: accounts, methods: element.methods, events: element.events)
            }
            let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events, extensions: extensions)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }
    
    func didRejectSession() {
        let proposal = currentProposal!
        currentProposal = nil
        reject(proposalId: proposal.id, reason: .disapprovedChains)
    }
}

extension WalletViewController {
    func setUpAuthSubscribing() {
        Sign.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    self?.onClientConnected?()
                    print("Client connected")
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

        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadActiveSessions()
            }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                print("[RESPONDER] WC: Did receive session request")
                self?.showSessionRequest(sessionRequest)
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                self?.reloadActiveSessions()
                self?.navigationController?.popToRootViewController(animated: true)
            }.store(in: &publishers)
    }

    private func getActiveSessionItem(for settledSessions: [Session]) -> [ActiveSessionItem] {
        return settledSessions.map { session -> ActiveSessionItem in
            let app = session.peer
            return ActiveSessionItem(
                dappName: app.name ?? "",
                dappURL: app.url ?? "",
                iconURL: app.icons.first ?? "",
                topic: session.topic)
        }
    }

    private func reloadActiveSessions() {
        let settledSessions = Sign.instance.getSessions()
        let activeSessions = getActiveSessionItem(for: settledSessions)
        DispatchQueue.main.async { // FIXME: Delegate being called from background thread
            self.sessionItems = activeSessions
            self.walletView.tableView.reloadData()
        }
    }
}
