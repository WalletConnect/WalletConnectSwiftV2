import Foundation
import WebKit

final class WebViewProxy {

    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    func execute(script: WebViewScript) {
        webView.evaluateJavaScript(script.build())
    }
}
