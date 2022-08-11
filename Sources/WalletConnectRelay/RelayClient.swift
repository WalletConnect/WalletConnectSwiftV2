import Foundation
import Combine
import WalletConnectUtils
import WalletConnectKMS
import JSONRPC

public enum SocketConnectionStatus {
    case connected
    case disconnected
}

public final class RelayClient {

    enum Errors: Error {
        case subscriptionIdNotFound
    }

    static let historyIdentifier = "com.walletconnect.sdk.relayer_client.subscription_json_rpc_record"

    public var onMessage: ((String, String) -> Void)?

    let defaultTtl = 6*Time.hour
    var subscriptions: [String: String] = [:]

    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    private let socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()

    private let subscriptionResponsePublisherSubject = PassthroughSubject<(RPCID?, String), Never>()
    private var subscriptionResponsePublisher: AnyPublisher<(RPCID?, String), Never> {
        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let requestAcknowledgePublisherSubject = PassthroughSubject<RPCID?, Never>()
    private var requestAcknowledgePublisher: AnyPublisher<RPCID?, Never> {
        requestAcknowledgePublisherSubject.eraseToAnyPublisher()
    }

    private var dispatcher: Dispatching
    private let rpcHistory: RPCHistory
    private let logger: ConsoleLogging

    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.relay_client", attributes: .concurrent)

    init(
        dispatcher: Dispatching,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage
    ) {
        self.logger = logger
        self.dispatcher = dispatcher
        self.rpcHistory = RPCHistory(keyValueStore: CodableStore<RPCHistory.Record>(defaults: keyValueStorage, identifier: Self.historyIdentifier))
        setUpBindings()
    }

    private func setUpBindings() {
        dispatcher.onMessage = { [weak self] payload in
            self?.handlePayloadMessage(payload)
        }
        dispatcher.onConnect = { [unowned self] in
            self.socketConnectionStatusPublisherSubject.send(.connected)
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
        let socketAuthenticator = SocketAuthenticator(
            clientIdStorage: ClientIdStorage(keychain: keychainStorage),
            didKeyFactory: ED25519DIDKeyFactory(),
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
        self.init(dispatcher: dispatcher, logger: logger, keyValueStorage: keyValueStorage)
    }

    public func connect() throws {
        try dispatcher.connect()
    }

    public func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        try dispatcher.disconnect(closeCode: closeCode)
    }

    /// Completes when networking client sends a request, error if it fails on client side
    public func publish(topic: String, payload: String, tag: Int, prompt: Bool = false) async throws {
        let request = Publish(params: .init(topic: topic, message: payload, ttl: defaultTtl, prompt: prompt, tag: tag))
            .wrapToIRN()
            .asRPCRequest()
        let message = try request.asJSONEncodedString()
        logger.debug("Publishing payload on topic: \(topic)")
        try await dispatcher.send(message)
    }

    /// Completes with an acknowledgement from the relay network.
    public func publish(
        topic: String,
        payload: String,
        tag: Int,
        prompt: Bool = false,
        onNetworkAcknowledge: @escaping ((Error?) -> Void)
    ) {
        let rpc = Publish(params: .init(topic: topic, message: payload, ttl: defaultTtl, prompt: prompt, tag: tag))
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
        dispatcher.send(message) { [weak self] error in
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
        dispatcher.send(message) { [weak self] error in
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
                    return
                }
                continuation.resume(returning: ())
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
        dispatcher.send(message) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to unsubscribe from topic")
                cancellable?.cancel()
                completion(error)
            } else {
                self?.concurrentQueue.async(flags: .barrier) {
                    self?.subscriptions[topic] = nil
                }
                completion(nil)
            }
        }
    }

    // FIXME: Parse data to string once before trying to decode -> respond error on fail
    private func handlePayloadMessage(_ payload: String) {
        if let request = tryDecode(RPCRequest.self, from: payload) {
            if let params = try? request.params?.get(Subscription.Params.self) {
                do {
                    try rpcHistory.set(request, forTopic: params.data.topic, emmitedBy: .remote)
                    try acknowledgeRequest(request)
                    onMessage?(params.data.topic, params.data.message)
                } catch {
                    logger.error("[RelayClient] RPC History 'set()' error: \(error)")
                }
            } else {
                logger.error("Unexpected request from network")
            }
        } else if let response = tryDecode(RPCResponse.self, from: payload) {
            switch response.outcome {
            case .success(let anyCodable):
                if let _ = try? anyCodable.get(Bool.self) { // TODO: Handle success vs. error
                    requestAcknowledgePublisherSubject.send(response.id)
                } else if let subscriptionId = try? anyCodable.get(String.self) {
                    subscriptionResponsePublisherSubject.send((response.id, subscriptionId))
                }
            case .failure(let rpcError):
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
        try rpcHistory.resolve(response)
        let message = try response.asJSONEncodedString()
        dispatcher.send(message) { [weak self] in
            if let error = $0 {
                self?.logger.debug("Failed to dispatch response: \(response), error: \(error)")
            }
        }
    }
}
