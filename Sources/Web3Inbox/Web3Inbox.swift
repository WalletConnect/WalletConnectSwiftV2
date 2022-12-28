import Foundation
import WebKit
import WalletConnectChat

final class Web3InboxClient {

    private let host: String
    private let clientProxy: ChatClientProxy
    private let clientSubscriber: ChatClientRequestSubscriper

    private let webviewProxy: WebViewProxy
    private let webviewSubscriber: WebViewRequestSubscriber

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(webviewSubscriber, name: WebViewRequestSubscriber.name)
        let webview = WKWebView(frame: .zero, configuration: configuration)
        let request = URLRequest(url: URL(string: host)!)
        webview.load(request)
        return webview
    }()

    init(
        host: String,
        clientProxy: ChatClientProxy,
        clientSubscriber: ChatClientRequestSubscriper,
        webviewProxy: WebViewProxy,
        webviewSubscriber: WebViewRequestSubscriber
    ) {
        self.host = host
        self.clientProxy = clientProxy
        self.clientSubscriber = clientSubscriber
        self.webviewProxy = webviewProxy
        self.webviewSubscriber = webviewSubscriber
    }

    private func setupSubscriptions() {
        webviewSubscriber.onRequest = { [unowned self] request in
            clientProxy.execute(request: request)
        }
        clientProxy.onResponse = { [unowned self] response in
            webviewProxy.execute(response: response)
        }
        clientSubscriber.onRequest = { [unowned self] request in
            webviewProxy.execute(request: request)
        }
    }
}
