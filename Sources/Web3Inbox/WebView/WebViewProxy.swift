import Foundation
import WebKit

actor WebViewProxy {

    private let webView: WKWebView
    private let scriptFormatter: WebViewScriptFormatter
    private let logger: ConsoleLogging

    init(webView: WKWebView,
         scriptFormatter: WebViewScriptFormatter,
         logger: ConsoleLogging) {
        self.webView = webView
        self.scriptFormatter = scriptFormatter
        self.logger = logger
    }

    @MainActor
    func respond(_ response: RPCResponse) async throws {
        let body = try response.json()
        logger.debug("resonding to w3i with \(body)")
        let script = scriptFormatter.formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    @MainActor
    func request(_ request: RPCRequest) async throws {
        let body = try request.json()
        logger.debug("requesting w3i with \(body)")
        let script = scriptFormatter.formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}


protocol WebViewScriptFormatter {
    func formatScript(body: String) -> String
}

class ChatWebViewScriptFormatter: WebViewScriptFormatter {
    func formatScript(body: String) -> String {
        return "window.web3inbox.chat.postMessage(\(body))"
    }
}

class PushWebViewScriptFormatter: WebViewScriptFormatter {
    func formatScript(body: String) -> String {
        return "window.web3inbox.push.postMessage(\(body))"
    }
}
