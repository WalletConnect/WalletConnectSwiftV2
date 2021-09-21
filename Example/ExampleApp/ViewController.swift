import UIKit
import WalletConnect

final class ViewController: UIViewController {

    let client: WalletConnectClient = {
        let options = WalletClientOptions(
            apiKey: "",
            name: "Example",
            isController: true,
            metadata: AppMetadata(name: "Example App", description: nil, url: nil, icons: nil),
            relayURL: URL(string: "wss://staging.walletconnect.org")!)
        return WalletConnectClient(options: options)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
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
        navigationController?.pushViewController(scannerViewController, animated: true)
    }
}

extension ViewController: ScannerViewControllerDelegate {
    
    func didScan(_ code: String) {
        navigationController?.popToViewController(self, animated: true)
        print(code)
        // TODO: Start pairing
    }
}
