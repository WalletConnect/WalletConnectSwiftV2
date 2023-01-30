import Foundation
import Combine

public enum SocketConnectionStatus {
    case connected
    case disconnected
}

/// WalletConnect Relay Client
///
/// Should not be instantiated outside of the SDK
///
/// Access via `Relay.instance`
public final class RelayClient {

    enum Errors: Error {
        case subscriptionIdNotFound
    }

    var subscriptions: [String: String] = [:]

    public var messagePublisher: AnyPublisher<(topic: String, message: String), Never> {
        messagePublisherSubject.eraseToAnyPublisher()
    }

    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        dispatcher.socketConnectionStatusPublisher
    }

    private let messagePublisherSubject = PassthroughSubject<(topic: String, message: String), Never>()

    private let subscriptionResponsePublisherSubject = PassthroughSubject<(RPCID?, String), Never>()
    private var subscriptionResponsePublisher: AnyPublisher<(RPCID?, String), Never> {
        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let requestAcknowledgePublisherSubject = PassthroughSubject<RPCID?, Never>()
    private var requestAcknowledgePublisher: AnyPublisher<RPCID?, Never> {
        requestAcknowledgePublisherSubject.eraseToAnyPublisher()
    }

    private let clientIdStorage: ClientIdStoring

    private var dispatcher: Dispatching
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.relay_client", attributes: .concurrent)

    // MARK: - Initialization

    init(
        dispatcher: Dispatching,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        clientIdStorage: ClientIdStoring
    ) {
        self.logger = logger
        self.dispatcher = dispatcher
        self.rpcHistory = RPCHistoryFactory.createForRelay(keyValueStorage: keyValueStorage)
        self.clientIdStorage = clientIdStorage
        setUpBindings()
    }

    private func setUpBindings() {
        dispatcher.onMessage = { [weak self] payload in
            self?.handlePayloadMessage(payload)
        }
    }

    /// Instantiates Relay Client
    /// - Parameters:
    ///   - relayHost: proxy server host that your application will use to connect to Relay Network. If you register your project at `www.walletconnect.com` you can use `relay.walletconnect.com`
    ///   - projectId: an optional parameter used to access the public WalletConnect infrastructure. Go to `www.walletconnect.com` for info.
    ///   - keyValueStorage: by default WalletConnect SDK will store sequences in UserDefaults
    ///   - socketConnectionType: socket connection type
    ///   - logger: logger instance
    public convenience init(
        relayHost: String,
        projectId: String,
        keyValueStorage: KeyValueStorage = UserDefaults.standard,
        keychainStorage: KeychainStorageProtocol = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk"),
        socketFactory: WebSocketFactory,
        socketConnectionType: SocketConnectionType = .automatic,
        logger: ConsoleLogging = ConsoleLogger(loggingLevel: .off)
    ) {
        let didKeyFactory = ED25519DIDKeyFactory()
        let clientIdStorage = ClientIdStorage(keychain: keychainStorage, didKeyFactory: didKeyFactory)
        let socketAuthenticator = SocketAuthenticator(
            clientIdStorage: clientIdStorage,
            didKeyFactory: didKeyFactory,
            relayHost: relayHost
        )
        let relayUrlFactory = RelayUrlFactory(socketAuthenticator: socketAuthenticator)
        let socket = socketFactory.create(with: relayUrlFactory.create(
            host: relayHost,
            projectId: projectId
        ))
        socket.request.addValue(EnvironmentInfo.userAgent, forHTTPHeaderField: "User-Agent")
        let socketConnectionHandler: SocketConnectionHandler
        switch socketConnectionType {
        case .automatic:
            socketConnectionHandler = AutomaticSocketConnectionHandler(socket: socket)
        case .manual:
            socketConnectionHandler = ManualSocketConnectionHandler(socket: socket)
        }
        let dispatcher = Dispatcher(socket: socket, socketConnectionHandler: socketConnectionHandler, logger: logger)
        self.init(dispatcher: dispatcher, logger: logger, keyValueStorage: keyValueStorage, clientIdStorage: clientIdStorage)
    }

    /// Connects web socket
    ///
    /// Use this method for manual socket connection only
    public func connect() throws {
        try dispatcher.connect()
    }

    /// Disconnects web socket
    ///
    /// Use this method for manual socket connection only
    public func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        try dispatcher.disconnect(closeCode: closeCode)
    }

    /// Completes when networking client sends a request, error if it fails on client side
    public func publish(topic: String, payload: String, tag: Int, prompt: Bool, ttl: Int) async throws {
        let request = Publish(params: .init(topic: topic, message: payload, ttl: ttl, prompt: prompt, tag: tag))
            .wrapToIRN()
            .asRPCRequest()
        let message = try request.asJSONEncodedString()
        logger.debug("Publishing payload on topic: \(topic)")
        try await dispatcher.protectedSend(message)
    }

    /// Completes with an acknowledgement from the relay network.
    public func publish(
        topic: String,
        payload: String,
        tag: Int,
        prompt: Bool,
        ttl: Int,
        onNetworkAcknowledge: @escaping ((Error?) -> Void)
    ) {
        let rpc = Publish(params: .init(topic: topic, message: payload, ttl: ttl, prompt: prompt, tag: tag))
        let request = rpc
            .wrapToIRN()
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        logger.debug("Publishing Payload on Topic: \(topic)")
        var cancellable: AnyCancellable?
        cancellable = requestAcknowledgePublisher
            .filter { $0 == request.id }
            .sink { (_) in
            cancellable?.cancel()
                onNetworkAcknowledge(nil)
        }
        dispatcher.protectedSend(message) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Publish Payload, error: \(error)")
                cancellable?.cancel()
                onNetworkAcknowledge(error)
            }
        }
    }

    @available(*, renamed: "subscribe(topic:)")
    public func subscribe(topic: String, completion: @escaping (Error?) -> Void) {
        logger.debug("Relay: Subscribing to topic: \(topic)")
        let rpc = Subscribe(params: .init(topic: topic))
        let request = rpc
            .wrapToIRN()
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        var cancellable: AnyCancellable?
        cancellable = subscriptionResponsePublisher
            .filter { $0.0 == request.id }
            .sink { [weak self] subscriptionInfo in
                cancellable?.cancel()
                self?.concurrentQueue.async(flags: .barrier) {
                    self?.subscriptions[topic] = subscriptionInfo.1
                }
                completion(nil)
        }
        dispatcher.protectedSend(message) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to subscribe to topic \(error)")
                cancellable?.cancel()
                completion(error)
            }
        }
    }

    public func subscribe(topic: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            subscribe(topic: topic) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    public func unsubscribe(topic: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            unsubscribe(topic: topic) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    public func batchSubscribe(topics: [String]) async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            for topic in topics {
                group.addTask {
                    try await self.subscribe(topic: topic)
                }
            }
        }
    }

    public func batchUnsubscribe(topics: [String]) async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            for topic in topics {
                group.addTask {
                    try await self.unsubscribe(topic: topic)
                }
            }
        }
    }

    public func unsubscribe(topic: String, completion: @escaping ((Error?) -> Void)) {
        guard let subscriptionId = subscriptions[topic] else {
            completion(Errors.subscriptionIdNotFound)
            return
        }
        logger.debug("Relay: Unsubscribing from topic: \(topic)")
        let rpc = Unsubscribe(params: .init(id: subscriptionId, topic: topic))
        let request = rpc
            .wrapToIRN()
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        rpcHistory.deleteAll(forTopic: topic)
        var cancellable: AnyCancellable?
        cancellable = requestAcknowledgePublisher
            .filter { $0 == request.id }
            .sink { (_) in
                cancellable?.cancel()
                completion(nil)
            }
        dispatcher.protectedSend(message) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to unsubscribe from topic")
                cancellable?.cancel()
                completion(error)
            } else {
                self?.concurrentQueue.async(flags: .barrier) {
                    self?.subscriptions[topic] = nil
                }
            }
        }
    }

    public func getClientId() throws -> String {
        try clientIdStorage.getClientId()
    }

    // FIXME: Parse data to string once before trying to decode -> respond error on fail
    private func handlePayloadMessage(_ payload: String) {
        if let request = tryDecode(RPCRequest.self, from: payload) {
            if let params = try? request.params?.get(Subscription.Params.self) {
                do {
                    try acknowledgeRequest(request)
                    try rpcHistory.set(request, forTopic: params.data.topic, emmitedBy: .remote)
                    logger.debug("topic \(params.data.topic)")
                    logger.debug("message: \(params.data.message)")
                    messagePublisherSubject.send((params.data.topic, params.data.message))
                } catch {
                    logger.error("[RelayClient] RPC History 'set()' error: \(error)")
                }
            } else {
                logger.error("Unexpected request from network")
            }
        } else if let response = tryDecode(RPCResponse.self, from: payload) {
            switch response.outcome {
            case .response(let anyCodable):
                if let _ = try? anyCodable.get(Bool.self) { // TODO: Handle success vs. error
                    requestAcknowledgePublisherSubject.send(response.id)
                } else if let subscriptionId = try? anyCodable.get(String.self) {
                    subscriptionResponsePublisherSubject.send((response.id, subscriptionId))
                }
            case .error(let rpcError):
                logger.error("Received RPC error from relay network: \(rpcError)")
            }
        } else {
            logger.error("Unexpected response from network")
        }
    }

    private func tryDecode<T: Decodable>(_ type: T.Type, from payload: String) -> T? {
        if let data = payload.data(using: .utf8),
           let response = try? JSONDecoder().decode(T.self, from: data) {
            return response
        } else {
            return nil
        }
    }

    private func acknowledgeRequest(_ request: RPCRequest) throws {
        let response = RPCResponse(matchingRequest: request, result: true)
        let message = try response.asJSONEncodedString()
        dispatcher.protectedSend(message) { [unowned self] in
            if let error = $0 {
                logger.debug("Failed to dispatch response: \(response), error: \(error)")
            } else {
                do {
                    try rpcHistory.resolve(response)
                } catch {
                    logger.debug(error)
                }
            }
        }
    }
}
