import Foundation
import WebKit

final class WebViewFactory {

    private let url: URL
    private let webviewSubscriber: WebViewRequestSubscriber

    init(url: URL, webviewSubscriber: WebViewRequestSubscriber) {
        self.url = url
        self.webviewSubscriber = webviewSubscriber
    }

    func create() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        #if os(iOS)
        configuration.allowsInlineMediaPlayback = true
        #endif
        configuration.userContentController.add(
            webviewSubscriber,
            name: WebViewRequestSubscriber.chat
        )
        configuration.userContentController.add(
            webviewSubscriber,
            name: WebViewRequestSubscriber.notify
        )
        let webview = WKWebView(frame: .zero, configuration: configuration)

        let request = URLRequest(url: url)
        webview.load(request)
        webview.uiDelegate = webviewSubscriber
        webview.navigationDelegate = webviewSubscriber
        return webview
    }
}
