import UIKit
import WalletConnectAuth
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
        let settledSessions = Auth.instance.getSessions()
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
    
    private func showSessionDetailsViewController(_ session: Session) {
        let vc = SessionDetailsViewController(session)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showSessionRequest(_ sessionRequest: Request) {
        let requestVC = RequestViewController(sessionRequest)
        requestVC.onSign = { [unowned self] in
            let result = Signer.signEth(request: sessionRequest)
            let response = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: result)
            Auth.instance.respond(topic: sessionRequest.topic, response: .response(response))
            reloadSessionDetailsIfNeeded()
        }
        requestVC.onReject = { [unowned self] in
            Auth.instance.respond(topic: sessionRequest.topic, response: .error(JSONRPCErrorResponse(id: sessionRequest.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))
            reloadSessionDetailsIfNeeded()
        }
        reloadSessionDetailsIfNeeded()
        present(requestVC, animated: true)
    }
    
    func reloadSessionDetailsIfNeeded() {
        if let sessionDetailsViewController = navigationController?.viewControllers.first(where: {$0 is SessionDetailsViewController}) as? SessionDetailsViewController {
            sessionDetailsViewController.reloadTable()
        }
    }
    
    private func pairClient(uri: String) {
        print("[RESPONDER] Pairing to: \(uri)")
        Task {
            do {
                try await Auth.instance.pair(uri: uri)
            } catch {
                print("[PROPOSER] Pairing connect error: \(error)")
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
                    try await Auth.instance.disconnect(topic: item.topic, reason: Reason(code: 0, message: "disconnect"))
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
        if let session = Auth.instance.getSessions().first{$0.topic == itemTopic} {
            showSessionDetailsViewController(session)
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
        print("[RESPONDER] Approving session...")
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
        try! Auth.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }
    
    func didRejectSession() {
        print("did reject session")
        let proposal = currentProposal!
        currentProposal = nil
        Auth.instance.reject(proposal: proposal, reason: .disapprovedChains)
    }
}

extension WalletViewController {
    func setUpAuthSubscribing() {
        Auth.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    self?.onClientConnected?()
                    print("Client connected")
                }
            }.store(in: &publishers)

        // TODO: Adapt proposal data to be used on the view
        Auth.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                print("[RESPONDER] WC: Did receive session proposal")
                self?.currentProposal = sessionProposal
                    self?.showSessionProposal(Proposal(proposal: sessionProposal)) // FIXME: Remove mock
            }.store(in: &publishers)

        Auth.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadActiveSessions()
            }.store(in: &publishers)

        Auth.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                print("[RESPONDER] WC: Did receive session request")
                self?.showSessionRequest(sessionRequest)
            }.store(in: &publishers)

        Auth.instance.sessionDeletePublisher
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
        let settledSessions = Auth.instance.getSessions()
        let activeSessions = getActiveSessionItem(for: settledSessions)
        DispatchQueue.main.async { // FIXME: Delegate being called from background thread
            self.sessionItems = activeSessions
            self.walletView.tableView.reloadData()
        }
    }
}
