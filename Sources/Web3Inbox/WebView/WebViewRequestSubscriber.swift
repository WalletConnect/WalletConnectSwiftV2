import Foundation
import WebKit

final class WebViewRequestSubscriber: NSObject, WKScriptMessageHandler {

    static let name = "web3inbox"

    var onRequest: ((RPCRequest) async throws -> Void)?
    var onLogin: (() async throws -> Void)?

    private let logger: ConsoleLogging

    init(logger: ConsoleLogging) {
        self.logger = logger
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == WebViewRequestSubscriber.name else { return }

        guard
            let dict = message.body as? [String: Any],
            let data = try? JSONSerialization.data(withJSONObject: dict),
            let request = try? JSONDecoder().decode(RPCRequest.self, from: data)
        else { return }

        Task {
            do {
                try await onRequest?(request)
            } catch {
                logger.error("WebView Request error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewRequestSubscriber: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView.url?.path == "/login" else { return }

        Task {
            try await onLogin?()
        }
    }
}
