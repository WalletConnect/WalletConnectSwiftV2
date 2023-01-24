import Foundation
import WebKit

actor WebViewProxy {

    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    @MainActor
    func respond(_ response: RPCResponse) async throws {
        let body = try response.json()
        let script = await formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    @MainActor
    func request(_ request: RPCRequest) async throws {
        let body = try request.json()
        let script = await formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}

private extension WebViewProxy {

    func formatScript(body: String) -> String {
        return "window.\(WebViewRequestSubscriber.name).chat.postMessage(\(body))"
    }
}
