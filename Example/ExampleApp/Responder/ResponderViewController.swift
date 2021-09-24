import UIKit
import WalletConnect

final class ResponderViewController: UIViewController {

    let client: WalletConnectClient = {
        let options = WalletClientOptions(
            apiKey: "",
            name: "Example",
            isController: true,
            metadata: AppMetadata(name: "Example App", description: nil, url: nil, icons: nil),
            relayURL: URL(string: "wss://staging.walletconnect.org")!)
        return WalletConnectClient(options: options)
    }()
    
    private let responderView: ResponderView = {
        ResponderView()
    }()
    
    override func loadView() {
        view = responderView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Wallet"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "qrcode.viewfinder"),
            style: .plain,
            target: self,
            action: #selector(showScanner)
        )
    }
    
    @objc
    private func showScanner() {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    private func showSessionProposal() {
        let proposalViewController = SessionViewController()
        proposalViewController.delegate = self
        proposalViewController.show(SessionInfo.mock())
        present(proposalViewController, animated: true)
    }
}

extension ResponderViewController: ScannerViewControllerDelegate {
    
    func didScan(_ code: String) {
        print(code)
        // TODO: Start pairing
    }
}

extension ResponderViewController: SessionViewControllerDelegate {
    
    func didApproveSession() {
        print("did approve session")
    }
    
    func didRejectSession() {
        print("did reject session")
    }
}
