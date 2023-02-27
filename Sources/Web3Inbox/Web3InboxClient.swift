import Foundation
import WebKit

public final class Web3InboxClient {

    private let webView: WKWebView
    private var account: Account
    private let logger: ConsoleLogging

    private let clientProxy: ChatClientProxy
    private let clientSubscriber: ChatClientRequestSubscriber

    private let webviewProxy: WebViewProxy
    private let webviewSubscriber: WebViewRequestSubscriber

    init(
        webView: WKWebView,
        account: Account,
        logger: ConsoleLogging,
        clientProxy: ChatClientProxy,
        clientSubscriber: ChatClientRequestSubscriber,
        webviewProxy: WebViewProxy,
        webviewSubscriber: WebViewRequestSubscriber
    ) {
        self.webView = webView
        self.account = account
        self.logger = logger
        self.clientProxy = clientProxy
        self.clientSubscriber = clientSubscriber
        self.webviewProxy = webviewProxy
        self.webviewSubscriber = webviewSubscriber

        setupSubscriptions()
    }

    public func getWebView() -> WKWebView {
        return webView
    }

    public func setAccount(
        _ account: Account,
        onSign: @escaping SigningCallback
    ) async throws {
        clientProxy.onSign = onSign
        try await authorize(account: account)
    }
}

// MARK: - Privates

private extension Web3InboxClient {

    func setupSubscriptions() {
        webviewSubscriber.onRequest = { [unowned self] request in
            try await self.clientProxy.request(request)
        }
        clientProxy.onResponse = { [unowned self] response in
            try await self.webviewProxy.respond(response)
        }
        clientSubscriber.onRequest = { [unowned self] request in
            try await self.webviewProxy.request(request)
        }
    }

    func authorize(account: Account) async throws {
        self.account = account

        let request = RPCRequest(
            method: ChatClientRequest.setAccount.method,
            params: ["account": account.address]
        )
        try await webviewProxy.request(request)
    }
}
