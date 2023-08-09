import Foundation
import WebKit

final class WebViewRequestSubscriber: NSObject, WKScriptMessageHandler {

    static let chat = "web3inboxChat"
    static let push = "web3inboxPush"

    var onChatRequest: ((RPCRequest) async throws -> Void)?
    var onPushRequest: ((RPCRequest) async throws -> Void)?

    private let url: URL
    private let logger: ConsoleLogging

    init(url: URL, logger: ConsoleLogging) {
        self.url = url
        self.logger = logger
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        logger.debug("WebViewRequestSubscriber: received request from w3i")
        guard
            let body = message.body as? String, let data = body.data(using: .utf8),
            let request = try? JSONDecoder().decode(RPCRequest.self, from: data)
        else { return }
        logger.debug("request method: \(request.method)")

        let name = message.name

        Task {
            do {
                switch name {
                case Self.chat:
                    try await onChatRequest?(request)
                case Self.push:
                    try await onPushRequest?(request)
                default:
                    break
                }
            } catch {
                logger.error("WebView Request error: \(error.localizedDescription). Request: \(request)")
            }
        }
    }
}

extension WebViewRequestSubscriber: WKUIDelegate {
    
    #if os(iOS)
    
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
    
    #endif
}

extension WebViewRequestSubscriber: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard
            let from = webView.url,
            let to = navigationAction.request.url
        else { return decisionHandler(.cancel) }

        if from.absoluteString.contains("/login") || to.absoluteString.contains("/login") {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: url))
        } else {
            decisionHandler(.allow)
        }
    }
}

