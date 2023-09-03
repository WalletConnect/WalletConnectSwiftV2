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
    func respond(_ response: RPCResponse, _ request: RPCRequest) async throws {
        let body = try response.json(dateEncodingStrategy: .millisecondsSince1970)
        let logProperties: [String: String] = ["method": request.method, "requestId": "\(request.id!)", "response": body]
        logger.debug("resonding to w3i request \(request.method) with \(body)", properties: logProperties)
        let script = scriptFormatter.formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    @MainActor
    func request(_ request: RPCRequest) async throws {
        let body = try request.json(dateEncodingStrategy: .millisecondsSince1970)
        let logProperties = ["method": request.method, "requestId": "\(request.id!)"]
        logger.debug("requesting w3i with \(body)", properties: logProperties)
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

class NotifyWebViewScriptFormatter: WebViewScriptFormatter {
    func formatScript(body: String) -> String {
        return "window.web3inbox.notify.postMessage(\(body))"
    }
}
