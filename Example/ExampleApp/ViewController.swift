import UIKit
import WalletConnect

class ViewController: UIViewController {

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
    }
}
