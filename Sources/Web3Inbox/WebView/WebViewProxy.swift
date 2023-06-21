import Foundation
import WebKit

class WebViewRefreshHandler {
    var webViewURLObserver: NSKeyValueObservation!
    let webView: WKWebView
    let initUrl: URL

    init(webView: WKWebView, initUrl: URL) {
        self.webView = webView
        self.initUrl = initUrl
//        let timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { timer in
//            print("Timer fired!")
//            webView.reload()
//        }
        self.webViewURLObserver = webView.observe(\.url, options: .new) { webview, change in
            print("URL: \(String(describing: change.newValue))")
            if let newValue = change.newValue,
               let url = newValue?.absoluteString,
               url.contains("/login") {
                let request = URLRequest(url: initUrl)
                webview.load(request)
            }
        }
    }
}

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
        let body = try response.json(dateEncodingStrategy: .millisecondsSince1970)
        logger.debug("resonding to w3i with \(body)")
        let script = scriptFormatter.formatScript(body: body)
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    @MainActor
    func request(_ request: RPCRequest) async throws {
        let body = try request.json(dateEncodingStrategy: .millisecondsSince1970)
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
