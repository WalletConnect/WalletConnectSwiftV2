import Foundation
import WebKit

final class WebViewFactory {

    private let host: String
    private let webviewSubscriber: WebViewRequestSubscriber

    init(host: String, webviewSubscriber: WebViewRequestSubscriber) {
        self.host = host
        self.webviewSubscriber = webviewSubscriber
    }

    func create() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(
            webviewSubscriber,
            name: WebViewRequestSubscriber.name
        )
        let webview = WKWebView(frame: .zero, configuration: configuration)
        webview.navigationDelegate = webviewSubscriber
        let request = URLRequest(url: URL(string: host)!)
        webview.load(request)
        return webview
    }
}
