import UIKit
import WalletConnect

final class ProposerViewController: UIViewController {
    
    let client: WalletConnectClient = {
        let metadata = AppMetadata(
            name: "Example Proposer",
            description: "a description",
            url: "wallet.connect",
            icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"])
        return WalletConnectClient(
            metadata: metadata,
            projectId: "52af113ee0c1e1a20f4995730196c13e",
            isController: false,
            relayHost: "relay.dev.walletconnect.com",
            clientName: "proposer"
        )
    }()
    
    var activeItems: [ActivePairingItem] = []
    private var currentURI: String?
    
    private let proposerView: ProposerView = {
        ProposerView()
    }()
    
    override func loadView() {
        view = proposerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Dapp"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Connect",
            style: .plain,
            target: self,
            action: #selector(connect)
        )
        proposerView.tableView.dataSource = self
        proposerView.tableView.delegate = self
        
        client.delegate = self
        client.logger.setLogging(level: .debug)

    }
    
    @objc
    private func connect() {
        print("[PROPOSER] Connecting to a pairing...")
        let permissions = Session.Permissions(
            blockchains: ["a chain"],
            methods: ["a method"],
            notifications: []
        )
        do {
            if let uri = try client.connect(sessionPermissions: permissions) {
                showConnectScreen(uriString: uri)
            }
        } catch {
            print("[PROPOSER] Pairing connect error: \(error)")
        }
    }
    
    private func showConnectScreen(uriString: String) {
        DispatchQueue.main.async { [unowned self] in
            let vc = ConnectViewController(uri: uriString)
            present(vc, animated: true, completion: nil)
        }
    }

}

extension ProposerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activeItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! ActivePairingCell
        cell.item = activeItems[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = activeItems[indexPath.row]
            client.disconnect(topic: item.topic, reason: Reason(code: 0, message: "disconnect"))
            activeItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Disconnect"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("did select row \(indexPath)")
    }
}

extension ProposerViewController: WalletConnectClientDelegate {

    func didReceive(sessionProposal: Session.Proposal) {
        print("[PROPOSER] WC: Did receive session proposal")
    }
    
    func didReceive(sessionRequest: Request) {
        print("[PROPOSER] WC: Did receive session request")
    }

    func didReceive(notification: Session.Notification, sessionTopic: String) {

    }

    func didUpgrade(sessionTopic: String, permissions: Session.Permissions) {

    }

    func didUpdate(sessionTopic: String, accounts: Set<String>) {

    }

    func didUpdate(pairingTopic: String, appMetadata: AppMetadata) {

    }

    func didDelete(sessionTopic: String, reason: Reason) {

    }

    func didSettle(session: Session) {
        print("[PROPOSER] WC: Did settle session")
    }
    
    func didSettle(pairing: Pairing) {
        print("[PROPOSER] WC: Did settle pairing")
        let settledPairings = client.getSettledPairings()
        let activePairings = settledPairings.map { pairing -> ActivePairingItem in
            let peer = pairing.peer
            return ActivePairingItem(
                peerName: peer?.name ?? "",
                peerURL: peer?.url ?? "",
                iconURL: peer?.icons?.first ?? "",
                topic: pairing.topic)
        }
        DispatchQueue.main.async {
            self.activeItems = activePairings
            self.proposerView.tableView.reloadData()
        }
    }
    
    func didReject(pendingSessionTopic: String, reason: Reason) {
        print("[PROPOSER] WC: Did reject session")
    }
}
