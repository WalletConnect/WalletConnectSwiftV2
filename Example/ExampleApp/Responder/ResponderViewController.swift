import UIKit
import WalletConnect
import WalletConnectUtils

final class ResponderViewController: UIViewController {

    let client: WalletConnectClient = {
        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"])
        return WalletConnectClient(
            metadata: metadata,
            projectId: "",
            isController: true,
            relayHost: "relay.walletconnect.org",
            clientName: "responder"
        )
    }()
    let account = "0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"
    var sessionItems: [ActiveSessionItem] = []
    var currentProposal: Session.Proposal?
    
    private let responderView: ResponderView = {
        ResponderView()
    }()
    
    override func loadView() {
        view = responderView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Wallet"
        responderView.scanButton.addTarget(self, action: #selector(showScanner), for: .touchUpInside)
        responderView.pasteButton.addTarget(self, action: #selector(showTextInput), for: .touchUpInside)
        
        responderView.tableView.dataSource = self
        responderView.tableView.delegate = self
        let settledSessions = client.getSettledSessions()
        sessionItems = getActiveSessionItem(for: settledSessions)
        client.delegate = self
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
    
    private func showSessionProposal(_ info: SessionInfo) {
        let proposalViewController = SessionViewController()
        proposalViewController.delegate = self
        proposalViewController.show(info)
        present(proposalViewController, animated: true)
    }
    
    private func showSessionDetailsViewController(_ session: Session) {
        let sessionInfo = SessionInfo(name: session.peer.name ?? "",
                                      descriptionText: session.peer.description ?? "",
                                      dappURL: session.peer.description ?? "",
                                      iconURL: session.peer.icons?.first ?? "",
                                      chains: Array(session.permissions.blockchains),
                                      methods: Array(session.permissions.methods))
        let vc = SessionDetailsViewController(sessionInfo)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showSessionRequest(_ sessionRequest: Request) {
        let requestVC = RequestViewController(sessionRequest)
        requestVC.onSign = { [weak self] in
            let result = "0xa3f20717a250c2b0b729b7e5becbff67fdaef7e0699da4de7ca5895b02a170a12d887fd3b17bfdce3481f10bea41f45ba9f709d39ce8325427b57afcfc994cee1b"
            let response = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: AnyCodable(result))
            self?.client.respond(topic: sessionRequest.topic, response: .response(response))
        }
        requestVC.onReject = { [weak self] in
            self?.client.respond(topic: sessionRequest.topic, response: .error(JSONRPCErrorResponse(id: sessionRequest.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))
        }
        present(requestVC, animated: true)
    }
    
    private func pairClient(uri: String) {
        print("[RESPONDER] Pairing to: \(uri)")
        do {
            try client.pair(uri: uri)
        } catch {
            print("[PROPOSER] Pairing connect error: \(error)")
        }
    }
}

extension ResponderViewController: UITableViewDataSource, UITableViewDelegate {
    
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
//            let deleteParams = SessionType.DeleteParams(topic: item.topic, reason: SessionType.Reason(code: 0, message: "disconnect"))
            client.disconnect(topic: item.topic, reason: Reason(code: 0, message: "disconnect"))
            sessionItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Disconnect"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("did select row \(indexPath)")
        let itemTopic = sessionItems[indexPath.row].topic
        if let session = client.getSettledSessions().first{$0.topic == itemTopic} {
            showSessionDetailsViewController(session)
        }
    }
}

extension ResponderViewController: ScannerViewControllerDelegate {
    
    func didScan(_ code: String) {
        pairClient(uri: code)
    }
}

extension ResponderViewController: SessionViewControllerDelegate {
    
    func didApproveSession() {
        print("[RESPONDER] Approving session...")
        let proposal = currentProposal!
        currentProposal = nil
        let accounts = proposal.permissions.blockchains.map {$0+":\(account)"}
        client.approve(proposal: proposal, accounts: Set(accounts))
    }
    
    func didRejectSession() {
        print("did reject session")
        let proposal = currentProposal!
        currentProposal = nil
        client.reject(proposal: proposal, reason: Reason(code: 0, message: "reject"))
    }
}

extension ResponderViewController: WalletConnectClientDelegate {
    
    func didReceive(sessionProposal: Session.Proposal) {
        print("[RESPONDER] WC: Did receive session proposal")
        let appMetadata = sessionProposal.proposer
        let info = SessionInfo(
            name: appMetadata.name ?? "",
            descriptionText: appMetadata.description ?? "",
            dappURL: appMetadata.url ?? "",
            iconURL: appMetadata.icons?.first ?? "",
            chains: Array(sessionProposal.permissions.blockchains),
            methods: Array(sessionProposal.permissions.methods))
        currentProposal = sessionProposal
        DispatchQueue.main.async { // FIXME: Delegate being called from background thread
            self.showSessionProposal(info)
        }
    }
    
    func didSettle(session: Session) {
        reloadActiveSessions()
    }
    
    func didReceive(sessionRequest: Request) {
        DispatchQueue.main.async { [weak self] in
            self?.showSessionRequest(sessionRequest)
        }
        print("[RESPONDER] WC: Did receive session request")
        
    }
    
    func didReceive(notification: Session.Notification, sessionTopic: String) {

    }

    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {

    }

    func didUpdate(sessionTopic: String, accounts: Set<String>) {

    }
    
    func didDelete(sessionTopic: String, reason: Reason) {
        reloadActiveSessions()
    }
    
    private func getActiveSessionItem(for settledSessions: [Session]) -> [ActiveSessionItem] {
        return settledSessions.map { session -> ActiveSessionItem in
            let app = session.peer
            return ActiveSessionItem(
                dappName: app.name ?? "",
                dappURL: app.url ?? "",
                iconURL: app.icons?.first ?? "",
                topic: session.topic)
        }
    }
    
    private func reloadActiveSessions() {
        let settledSessions = client.getSettledSessions()
        let activeSessions = getActiveSessionItem(for: settledSessions)
        DispatchQueue.main.async { // FIXME: Delegate being called from background thread
            self.sessionItems = activeSessions
            self.responderView.tableView.reloadData()
        }
    }
}

extension UIAlertController {
    
    static func createInputAlert(confirmHandler: @escaping (String) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Paste URI", message: "Enter a WalletConnect URI to connect.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let confirmAction = UIAlertAction(title: "Connect", style: .default) { _ in
            if let input = alert.textFields?.first?.text, !input.isEmpty {
                confirmHandler(input)
            }
        }
        alert.addTextField { textField in
            textField.placeholder = "wc://a14aefb980188fc35ec9..."
        }
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        alert.preferredAction = confirmAction
        return alert
    }
}
