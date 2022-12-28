import Foundation
import WebKit
import JSONRPC

final class WebViewRequestSubscriber: NSObject, WKScriptMessageHandler {

    static let name = "web3InboxHandler"

    var onRequest: ((WebViewRequest) -> Void)?

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == WebViewRequestSubscriber.name else { return }

        guard
            let dict = message.body as? [String: Any],
            let data = try? JSONSerialization.data(withJSONObject: dict),
            let request = try? JSONDecoder().decode(RPCRequest.self, from: data),
            let event = try? request.params?.get(WebViewRequest.self)
        else { return }

        onRequest?(event)
    }
}
