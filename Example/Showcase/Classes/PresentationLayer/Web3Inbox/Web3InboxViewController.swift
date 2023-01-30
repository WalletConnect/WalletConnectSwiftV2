import UIKit
import Web3Inbox
import WebKit

final class Web3InboxViewController: UIViewController {

    private let account: Account

    init(account: Account) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Web3Inbox.configure(account: account)
        view = Web3Inbox.instance.getWebView()

        navigationItem.title = "Web3Inbox SDK"
    }
}
