import UIKit
import Web3Inbox
import WebKit

final class Web3InboxViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = Web3Inbox.instance.getWebView()
    }
}
