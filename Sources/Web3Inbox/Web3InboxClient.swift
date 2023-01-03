import Foundation
import WebKit
import WalletConnectChat

public final class Web3InboxClient {

    private let webView: WKWebView

    private let clientProxy: ChatClientProxy
    private let clientSubscriber: ChatClientRequestSubscriper

    private let webviewProxy: WebViewProxy
    private let webviewSubscriber: WebViewRequestSubscriber

    init(
        webView: WKWebView,
        clientProxy: ChatClientProxy,
        clientSubscriber: ChatClientRequestSubscriper,
        webviewProxy: WebViewProxy,
        webviewSubscriber: WebViewRequestSubscriber
    ) {
        self.webView = webView
        self.clientProxy = clientProxy
        self.clientSubscriber = clientSubscriber
        self.webviewProxy = webviewProxy
        self.webviewSubscriber = webviewSubscriber
    }

    public func getWebView() -> WKWebView {
        return webView
    }
}

// MARK: - Privates

private extension Web3InboxClient {

    func setupSubscriptions() {
        webviewSubscriber.onRequest = { [unowned self] request in
            clientProxy.execute(request: request)
        }
        clientProxy.onResponse = { [unowned self] response in
            webviewProxy.execute(script: response)
        }
        clientSubscriber.onRequest = { [unowned self] request in
            webviewProxy.execute(script: request)
        }
    }
}
