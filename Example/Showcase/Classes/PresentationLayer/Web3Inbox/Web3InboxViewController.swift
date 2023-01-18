import UIKit
import Web3Inbox
import WebKit

final class Web3InboxViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Web3Inbox.configure(account: Account("eip155:1:0x2F871A068a16BF4a970663dF5e417951aB79Bfd3")!)
        self.view = Web3Inbox.instance.getWebView()
    }
}
