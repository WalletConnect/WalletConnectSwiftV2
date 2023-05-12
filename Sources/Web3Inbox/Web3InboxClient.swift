import Foundation
import WebKit

public final class Web3InboxClient {

    private let webView: WKWebView
    private var account: Account
    private let logger: ConsoleLogging

    private let chatClientProxy: ChatClientProxy
    private let chatClientSubscriber: ChatClientRequestSubscriber

    private let pushClientProxy: PushClientProxy
    private let pushClientSubscriber: PushClientRequestSubscriber

    private let chatWebviewProxy: WebViewProxy
    private let pushWebviewProxy: WebViewProxy

    private let chatWebviewSubscriber: WebViewRequestSubscriber
    private let pushWebviewSubscriber: WebViewRequestSubscriber

init(
        webView: WKWebView,
        account: Account,
        logger: ConsoleLogging,
        chatClientProxy: ChatClientProxy,
        clientSubscriber: ChatClientRequestSubscriber,
        chatWebviewProxy: WebViewProxy,
        pushWebviewProxy: WebViewProxy,
        chatWebviewSubscriber: WebViewRequestSubscriber,
        pushWebviewSubscriber: WebViewRequestSubscriber,
        pushClientProxy: PushClientProxy,
        pushClientSubscriber: PushClientRequestSubscriber
    ) {
        self.webView = webView
        self.account = account
        self.logger = logger
        self.chatClientProxy = chatClientProxy
        self.chatClientSubscriber = clientSubscriber
        self.chatWebviewProxy = chatWebviewProxy
        self.pushWebviewProxy = pushWebviewProxy
        self.chatWebviewSubscriber = chatWebviewSubscriber
        self.pushWebviewSubscriber = pushWebviewSubscriber
        self.pushClientProxy = pushClientProxy
        self.pushClientSubscriber = pushClientSubscriber

        setupSubscriptions()
    }

    public func getWebView() -> WKWebView {
        return webView
    }

    public func setAccount(
        _ account: Account,
        onSign: @escaping SigningCallback
    ) async throws {
        chatClientProxy.onSign = onSign
        try await authorize(account: account)
    }
}

// MARK: - Privates

private extension Web3InboxClient {

    func setupSubscriptions() {

        // Chat
        
        chatClientProxy.onResponse = { [unowned self] response in
            try await self.chatWebviewProxy.respond(response)
        }

        chatClientSubscriber.onRequest = { [unowned self] request in
            try await self.chatWebviewProxy.request(request)
        }

        chatWebviewSubscriber.onRequest = { [unowned self] request in
            logger.debug("w3i: chat method \(request.method) requested")
            try await self.chatClientProxy.request(request)
        }

        // Push

        pushClientProxy.onResponse = { [unowned self] response in
            try await self.pushWebviewProxy.respond(response)
        }

        pushClientSubscriber.onRequest = { [unowned self] request in
            try await self.pushWebviewProxy.request(request)
        }

        pushWebviewSubscriber.onRequest = { [unowned self] request in
            logger.debug("w3i: push method \(request.method) requested")
            try await self.pushClientProxy.request(request)
        }
    }

    func authorize(account: Account) async throws {
        self.account = account

        let request = RPCRequest(
            method: ChatClientRequest.setAccount.method,
            params: ["account": account.address]
        )
        try await chatWebviewProxy.request(request)
    }
}
