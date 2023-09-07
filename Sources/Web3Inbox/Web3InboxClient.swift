import Foundation
import WebKit
import Combine

public final class Web3InboxClient {

    private let webView: WKWebView
    private var account: Account
    private let logger: ConsoleLogging
    private let notifyClient: NotifyClient

    private let chatClientProxy: ChatClientProxy
    private let chatClientSubscriber: ChatClientRequestSubscriber

    private let notifyClientProxy: NotifyClientProxy
    private let notifyClientSubscriber: NotifyClientRequestSubscriber

    private let chatWebviewProxy: WebViewProxy
    private let notifyWebviewProxy: WebViewProxy

    private let webviewSubscriber: WebViewRequestSubscriber

    public var logsPublisher: AnyPublisher<Log, Never> {
        logger.logsPublisher
            .merge(with: notifyClient.logsPublisher)
            .eraseToAnyPublisher()
    }

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
        notifyClient: NotifyClient
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


    public func setLogging(level: LoggingLevel) {
        logger.setLogging(level: level)
        notifyClient.setLogging(level: .debug)
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

    public func reload() {
        webviewSubscriber.reload(webView)
    }
}

// MARK: - Privates

private extension Web3InboxClient {

    func setupSubscriptions() {

        // Chat
        
        chatClientProxy.onResponse = { [unowned self] response, request in
            try await self.chatWebviewProxy.respond(response, request)
        }

        chatClientSubscriber.onRequest = { [unowned self] request in
            try await self.chatWebviewProxy.request(request)
        }

        webviewSubscriber.onChatRequest = { [unowned self] request in
            logger.debug("w3i: method \(request.method) requested")
            try await self.chatClientProxy.request(request)
        }

        // Notify

        notifyClientProxy.onResponse = { [unowned self] response, request in
            try await self.notifyWebviewProxy.respond(response, request)
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
