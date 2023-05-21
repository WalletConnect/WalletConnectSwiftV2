import Foundation
import WebKit

final class WebViewFactory {

    private let url: URL
    private let chatWebviewSubscriber: WebViewRequestSubscriber
    private let pushWebviewSubscriber: WebViewRequestSubscriber

    init(
        url: URL,
        chatWebviewSubscriber: WebViewRequestSubscriber,
        pushWebviewSubscriber: WebViewRequestSubscriber
    ) {
        self.url = url
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

        let request = URLRequest(url: url)
        webview.load(request)
        webview.uiDelegate = chatWebviewSubscriber
        return webview
    }
}
