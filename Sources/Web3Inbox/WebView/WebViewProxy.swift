import Foundation
import WebKit

actor WebViewProxy {

    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    func respond(_ response: RPCResponse) async throws {
        let body = try response.json()
        let script = formatScript(body: body)
        await webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func request(_ request: RPCRequest) async throws {
        let body = try request.json()
        let script = formatScript(body: body)
        await webView.evaluateJavaScript(script, completionHandler: nil)
    }
}

private extension WebViewProxy {

    func formatScript(body: String) -> String {
        return "window.\(WebViewRequestSubscriber.name).chat.postMessage(\(body))"
    }
}
