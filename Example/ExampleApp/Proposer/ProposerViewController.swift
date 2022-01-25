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
    
    var activeItems: [ActiveSessionItem] = []
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
        
        proposerView.copyButton.addTarget(self, action: #selector(copyURI), for: .touchUpInside)
        proposerView.copyButton.isHidden = true
        
        proposerView.tableView.dataSource = self
        proposerView.tableView.delegate = self
        
        client.delegate = self
        client.logger.setLogging(level: .debug)
    }
    
    @objc func copyURI() {
        UIPasteboard.general.string = currentURI
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
                showQRCode(uriString: uri)
            }
        } catch {
            print("[PROPOSER] Pairing connect error: \(error)")
        }
    }
    
    private func showQRCode(uriString: String) {
        currentURI = uriString
        DispatchQueue.global().async { [weak self] in
            if let qrImage = self?.generateQRCode(from: uriString) {
                DispatchQueue.main.async {
                    self?.proposerView.qrCodeView.image = qrImage
                    self?.proposerView.copyButton.isHidden = false
                }
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            if let output = filter.outputImage {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
}

extension ProposerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activeItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! ActiveSessionCell
        cell.item = activeItems[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
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
        let activePairings = settledPairings.map { pairing -> ActiveSessionItem in
            let app = pairing.peer
            return ActiveSessionItem(
                dappName: app?.name ?? "",
                dappURL: app?.url ?? "",
                iconURL: app?.icons?.first ?? "",
                topic: pairing.topic)
        }
        DispatchQueue.main.async {
            self.activeItems = activePairings
            self.proposerView.tableView.reloadData()
            self.proposerView.qrCodeView.image = nil
            self.proposerView.copyButton.isHidden = true
        }
    }
    
    func didReject(pendingSessionTopic: String, reason: Reason) {
        print("[PROPOSER] WC: Did reject session")
    }
}
