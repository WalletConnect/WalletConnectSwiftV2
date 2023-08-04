import UIKit
import WebKit
import Web3Inbox

final class Web3InboxViewController: UIViewController {

    private var webView: WKWebView? {
        return view as? WKWebView
    }

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

        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped))
        let getUrl = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(getUrlPressed))

        navigationItem.rightBarButtonItems = [refresh, getUrl]
    }

    @objc func refreshTapped() {
        webView?.reload()
    }

    @objc func getUrlPressed(_ sender: UIBarItem) {
        UIPasteboard.general.string = webView?.url?.absoluteString

        let alert = UIAlertController(title: "URL copied to clipboard", message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }
}



