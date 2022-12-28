import Foundation
import WebKit

final class WebViewProxy {

    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    func execute(request: ChatClientRequest) {
        switch request {
        case .chatInvite(let invite):
            break // TODO: Implement me
        }
    }

    func execute(response: WebViewResponse) {
        switch response {
        case .getInvites(let invites):
            break // TODO: Implement me
        }
    }
}
