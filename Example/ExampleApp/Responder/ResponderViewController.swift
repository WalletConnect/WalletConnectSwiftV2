import UIKit
import WalletConnect
import WalletConnectUtils
import Web3
import CryptoSwift

final class ResponderViewController: UIViewController {

    let client: WalletConnectClient = {
        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"])
        return WalletConnectClient(
            metadata: metadata,
            projectId: "52af113ee0c1e1a20f4995730196c13e",
            isController: true,
            relayHost: "relay.dev.walletconnect.com", //use with dapp at https://canary.react-app.walletconnect.com/
            clientName: "responder"
        )
    }()
    lazy  var account = privateKey.address.hex(eip55: true)
    var sessionItems: [ActiveSessionItem] = []
    var currentProposal: Session.Proposal?
    let privateKey: EthereumPrivateKey = try! EthereumPrivateKey(hexPrivateKey: "0xe56da0e170b5e09a8bb8f1b693392c7d56c3739a9c75740fbc558a2877868540")
    
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
        let vc = SessionDetailsViewController(session, client)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showSessionRequest(_ sessionRequest: Request) {
        let requestVC = RequestViewController(sessionRequest)
        requestVC.onSign = { [unowned self] in
            let result = signEth(request: sessionRequest)
            let response = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: result)
            client.respond(topic: sessionRequest.topic, response: .response(response))
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
    
    func signEth(request: Request) -> AnyCodable {
        let method = request.method
        if method == "personal_sign" {
            let params = try! request.params.get([String].self)
            let messageToSign = params[0]
            let signHash = signHash(messageToSign)
            let (v, r, s) = try! self.privateKey.sign(hash: signHash)
            let result = "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16)
            return AnyCodable(result)
        } else if method == "eth_signTypedData" {
            let params = try! request.params.get([String].self)
            print(params)
            let messageToSign = params[1]
            let signHash = signHash(messageToSign)
            let (v, r, s) = try! self.privateKey.sign(hash: signHash)
            let result = "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16)
            return AnyCodable(result)
        } else if method == "eth_sendTransaction" {
            let params = try! request.params.get([EthereumTransaction].self)
            var transaction = params[0]
            transaction.gas = EthereumQuantity(quantity: BigUInt("1234"))
            print(transaction.description)
            let signedTx = try! transaction.sign(with: self.privateKey, chainId: 4)
            let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
            let result = r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
            return AnyCodable(result)
        }
        fatalError("not implemented")
    }
    
    func signHash(_ message: String) -> Bytes {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let messageData = Data(hex: message)
        let prefixData = (prefix + String(messageData.count)).data(using: .utf8)!
        let prefixedMessageData = prefixData + messageData
        let dataToHash: Bytes = .init(hex: prefixedMessageData.toHexString())
        return SHA3(variant: .keccak256).calculate(for: dataToHash)
    }
}
    
extension EthereumTransaction {
    var description: String {
        return """
        from: \(String(describing: from!.hex(eip55: true)))
        to: \(String(describing: to!.hex(eip55: true))),
        value: \(String(describing: value!.hex())),
        gasPrice: \(String(describing: gasPrice?.hex())),
        gas: \(String(describing: gas?.hex())),
        data: \(data.hex()),
        nonce: \(String(describing: nonce?.hex()))
        """
    }
}
