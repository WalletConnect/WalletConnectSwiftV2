import Foundation
import WebKit

final class WebViewFactory {

    private let host: String
    private let chatWebviewSubscriber: WebViewRequestSubscriber
    private let pushWebviewSubscriber: WebViewRequestSubscriber

    init(
        host: String,
        chatWebviewSubscriber: WebViewRequestSubscriber,
        pushWebviewSubscriber: WebViewRequestSubscriber
    ) {
        self.host = host
        self.chatWebviewSubscriber = chatWebviewSubscriber
        self.pushWebviewSubscriber = pushWebviewSubscriber
    }

    func create() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.userContentController.add(
            chatWebviewSubscriber,
            name: WebViewRequestSubscriber.chat
        )
        configuration.userContentController.add(
            pushWebviewSubscriber,
            name: WebViewRequestSubscriber.push
        )
        let webview = WKWebView(frame: .zero, configuration: configuration)
        let request = URLRequest(url: URL(string: host)!)
        webview.load(request)
        webview.uiDelegate = webviewSubscriber
        return webview
    }
}
