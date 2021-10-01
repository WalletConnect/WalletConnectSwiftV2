import UIKit
import WalletConnect

final class ProposerViewController: UIViewController {
    
    let client: WalletConnectClient = {
        let options = WalletClientOptions(
            apiKey: "",
            name: "Example Proposer",
            isController: false,
            metadata: AppMetadata(
                name: "Example Dapp",
                description: "a description",
                url: "wallet.connect",
                icons: ["https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media"]),
            relayURL: URL(string: "wss://staging.walletconnect.org")!)
        return WalletConnectClient(options: options)
    }()
    
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
        
        client.delegate = self
    }
    
    @objc func copyURI() {
        UIPasteboard.general.string = currentURI
    }
    
    @objc
    private func connect() {
        print("[PROPOSER] Connecting to a pairing...")
        let connectParams = ConnectParams(
            permissions: SessionType.Permissions(
                blockchain: SessionType.Blockchain(chains: ["a chain"]),
                jsonrpc: SessionType.JSONRPC(methods: ["a method"])))
        
        do {
            if let uri = try client.connect(params: connectParams) {
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

extension ProposerViewController: WalletConnectClientDelegate {
    
    func didReceive(sessionProposal: SessionType.Proposal) {
        print("[PROPOSER] WC: Did receive session proposal")
    }
    
    func didReceive(sessionRequest: SessionRequest) {
        print("[PROPOSER] WC: Did receive session request")
    }
    
    func didSettle(session: SessionType.Settled) {
        print("[PROPOSER] WC: Did settle session")
    }
    
    func didSettle(pairing: PairingType.Settled) {
        print("[PROPOSER] WC: Did settle pairing")
    }
    
    func didReject(sessionPendingTopic: String, reason: SessionType.Reason) {
        print("[PROPOSER] WC: Did reject session")
    }
}
