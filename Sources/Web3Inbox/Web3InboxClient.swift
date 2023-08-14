import Foundation
import WebKit

public final class Web3InboxClient {

    private let webView: WKWebView
    private var account: Account
    private let logger: ConsoleLogging
    private let notifyClient: WalletNotifyClient

    private let chatClientProxy: ChatClientProxy
    private let chatClientSubscriber: ChatClientRequestSubscriber

    private let notifyClientProxy: NotifyClientProxy
    private let notifyClientSubscriber: NotifyClientRequestSubscriber

    private let chatWebviewProxy: WebViewProxy
    private let notifyWebviewProxy: WebViewProxy

    private let webviewSubscriber: WebViewRequestSubscriber

    init(
        webView: WKWebView,
        account: Account,
        logger: ConsoleLogging,
        chatClientProxy: ChatClientProxy,
        clientSubscriber: ChatClientRequestSubscriber,
        chatWebviewProxy: WebViewProxy,
        notifyWebviewProxy: WebViewProxy,
        webviewSubscriber: WebViewRequestSubscriber,
        notifyClientProxy: NotifyClientProxy,
        notifyClientSubscriber: NotifyClientRequestSubscriber,
        notifyClient: WalletNotifyClient
    ) {
        self.webView = webView
        self.account = account
        self.logger = logger
        self.chatClientProxy = chatClientProxy
        self.chatClientSubscriber = clientSubscriber
        self.chatWebviewProxy = chatWebviewProxy
        self.notifyWebviewProxy = notifyWebviewProxy
        self.webviewSubscriber = webviewSubscriber
        self.notifyClientProxy = notifyClientProxy
        self.notifyClientSubscriber = notifyClientSubscriber
        self.notifyClient = notifyClient
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

    public func register(deviceToken: Data) async throws {
        try await notifyClient.register(deviceToken: deviceToken)
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

        webviewSubscriber.onChatRequest = { [unowned self] request in
            logger.debug("w3i: method \(request.method) requested")
            try await self.chatClientProxy.request(request)
        }

        // Notify

        notifyClientProxy.onResponse = { [unowned self] response in
            try await self.notifyWebviewProxy.respond(response)
        }

        notifyClientSubscriber.onRequest = { [unowned self] request in
            try await self.notifyWebviewProxy.request(request)
        }

        webviewSubscriber.onNotifyRequest = { [unowned self] request in
            logger.debug("w3i: notify method \(request.method) requested")
            try await self.notifyClientProxy.request(request)
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
