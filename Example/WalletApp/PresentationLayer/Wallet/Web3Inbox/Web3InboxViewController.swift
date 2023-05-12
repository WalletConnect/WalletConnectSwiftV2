import UIKit
import WebKit
import Web3Inbox

final class Web3InboxViewController: UIViewController {


    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = []
        navigationItem.title = "Web3Inbox SDK"
        navigationItem.largeTitleDisplayMode = .never
        view = Web3Inbox.instance.getWebView()
    }
}



