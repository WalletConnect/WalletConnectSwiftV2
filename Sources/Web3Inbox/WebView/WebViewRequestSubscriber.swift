import Foundation
import WebKit

final class WebViewRequestSubscriber: NSObject, WKScriptMessageHandler {

    static let name = "web3inbox"

    var onRequest: ((RPCRequest) async throws -> Void)?

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
            let body = message.body as? String, let data = body.data(using: .utf8),
            let request = try? JSONDecoder().decode(RPCRequest.self, from: data)
        else { return }

        Task {
            do {
                try await onRequest?(request)
            } catch {
                logger.error("WebView Request error: \(error.localizedDescription). Request: \(request)")
            }
        }
    }
}
