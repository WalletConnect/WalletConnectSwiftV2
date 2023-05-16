import Foundation
import WebKit

final class WebViewRequestSubscriber: NSObject, WKScriptMessageHandler {

    static let chat = "web3inboxChat"
    static let push = "web3inboxPush"

    var onRequest: ((RPCRequest) async throws -> Void)?

    private let logger: ConsoleLogging

    init(logger: ConsoleLogging) {
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
        Task {
            do {
                try await onRequest?(request)
            } catch {
                logger.error("WebView Request error: \(error.localizedDescription). Request: \(request)")
            }
        }
    }
}

extension WebViewRequestSubscriber: WKUIDelegate {

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}
