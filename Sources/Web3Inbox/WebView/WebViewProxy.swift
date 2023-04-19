import Foundation
import WebKit

actor WebViewProxy {

    private let webView: WKWebView
    private let scriptFormatter: WebViewScriptFormatter
    init(webView: WKWebView,
         scriptFormatter: WebViewScriptFormatter) {
        self.webView = webView
        self.scriptFormatter = scriptFormatter
    }

    @MainActor
    func respond(_ response: RPCResponse) async throws {
        let body = try response.json()
        let script = scriptFormatter.formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    @MainActor
    func request(_ request: RPCRequest) async throws {
        let body = try request.json()
        let script = scriptFormatter.formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}


protocol WebViewScriptFormatter {
    func formatScript(body: String) -> String
}

class ChatWebViewScriptFormatter: WebViewScriptFormatter {
    func formatScript(body: String) -> String {
        return "window.\(WebViewRequestSubscriber.name).chat.postMessage(\(body))"
    }
}

class PushWebViewScriptFormatter: WebViewScriptFormatter {
    func formatScript(body: String) -> String {
        return "window.\(WebViewRequestSubscriber.name).push.postMessage(\(body))"
    }
}
