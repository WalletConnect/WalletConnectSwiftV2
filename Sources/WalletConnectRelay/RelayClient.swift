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
    enum RelyerError: Error {
        case subscriptionIdNotFound
    }
    private typealias SubscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>
    private typealias SubscriptionResponse = JSONRPCResponse<String>
    private typealias RequestAcknowledgement = JSONRPCResponse<Bool>
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.relay_client",
                                                attributes: .concurrent)
    let jsonRpcSubscriptionsHistory: JsonRpcHistory<RelayJSONRPC.SubscriptionParams>
    public var onMessage: ((String, String) -> Void)?
    private var dispatcher: Dispatching
    var subscriptions: [String: String] = [:]
    let defaultTtl = 6*Time.hour

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
    let logger: ConsoleLogging
    static let historyIdentifier = "com.walletconnect.sdk.relayer_client.subscription_json_rpc_record"

    init(
        dispatcher: Dispatching,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage
    ) {
        self.logger = logger
        self.dispatcher = dispatcher

        self.jsonRpcSubscriptionsHistory = JsonRpcHistory<RelayJSONRPC.SubscriptionParams>(logger: logger, keyValueStore: CodableStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: Self.historyIdentifier))
        setUpBindings()
    }

    /// Instantiates Relay Client
    /// - Parameters:
    ///   - relayHost: proxy server host that your application will use to connect to Iridium Network. If you register your project at `www.walletconnect.com` you can use `relay.walletconnect.com`
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
        let params = RelayJSONRPC.PublishParams(topic: topic, message: payload, ttl: defaultTtl, prompt: prompt, tag: tag)
        let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.method, params: params)
        logger.debug("Publishing Payload on Topic: \(topic)")
        let requestJson = try request.json()
        try await dispatcher.send(requestJson)
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
            .wrapToIridium()
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        logger.debug("iridium: Publishing Payload on Topic: \(topic)")
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
        logger.debug("iridium: Subscribing on Topic: \(topic)")
        let rpc = Subscribe(params: .init(topic: topic))
        let request = rpc
            .wrapToIridium()
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
                self?.logger.debug("Failed to Subscribe on Topic \(error)")
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
            completion(RelyerError.subscriptionIdNotFound)
            return
        }
        logger.debug("iridium: Unsubscribing on Topic: \(topic)")
        let rpc = Unsubscribe(params: .init(id: subscriptionId, topic: topic))
        let request = rpc
            .wrapToIridium()
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        jsonRpcSubscriptionsHistory.delete(topic: topic)
        var cancellable: AnyCancellable?
        cancellable = requestAcknowledgePublisher
            .filter { $0 == request.id }
            .sink { (_) in
                cancellable?.cancel()
                completion(nil)
            }
        dispatcher.send(message) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Unsubscribe on Topic")
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

    private func setUpBindings() {
        dispatcher.onMessage = { [weak self] payload in
            self?.handlePayloadMessage(payload)
        }
        dispatcher.onConnect = { [unowned self] in
            self.socketConnectionStatusPublisherSubject.send(.connected)
        }
    }

    private func handlePayloadMessage(_ payload: String) {
        if let request = tryDecode(SubscriptionRequest.self, from: payload), validate(request: request, method: .subscription) {
            do {
                try jsonRpcSubscriptionsHistory.set(topic: request.params.data.topic, request: request)
                onMessage?(request.params.data.topic, request.params.data.message)
                acknowledgeSubscription(requestId: request.id)
            } catch {
                logger.info("Relay Client Info: Json Rpc Duplicate Detected")
            }
        } else if let response = tryDecode(RPCResponse.self, from: payload) {
            // use this
            switch response.outcome {
            case .success(let anyCodable):
                if let _ = try? anyCodable.get(Bool.self) { // TODO: Handle success vs. error
                    requestAcknowledgePublisherSubject.send(response.id)
                } else if let subscriptionId = try? anyCodable.get(String.self) {
                    subscriptionResponsePublisherSubject.send((response.id, subscriptionId))
                }
            case .failure(let rpcError):
                logger.error("Received error message from iridium network, code: \(rpcError.code), message: \(rpcError.message)")
            }
//        } else if let response = tryDecode(RequestAcknowledgement.self, from: payload) {
//            requestAcknowledgePublisherSubject.send(response)
//        } else if let response = tryDecode(SubscriptionResponse.self, from: payload) {
//            subscriptionResponsePublisherSubject.send(response)
        } else if let response = tryDecode(JSONRPCErrorResponse.self, from: payload) {
            logger.error("Received error message from iridium network, code: \(response.error.code), message: \(response.error.message)")
        } else {
            logger.error("Unexpected response from network")
        }
    }

    private func validate<T>(request: JSONRPCRequest<T>, method: RelayJSONRPC.Method) -> Bool {
        return request.method.contains(method.name)
    }

    private func tryDecode<T: Decodable>(_ type: T.Type, from payload: String) -> T? {
        if let data = payload.data(using: .utf8),
           let response = try? JSONDecoder().decode(T.self, from: data) {
            return response
        } else {
            return nil
        }
    }

    private func acknowledgeSubscription(requestId: Int64) {
        let response = JSONRPCResponse(id: requestId, result: AnyCodable(true))
        let responseJson = try! response.json()
        _ = try? jsonRpcSubscriptionsHistory.resolve(response: JsonRpcResult.response(response))
        dispatcher.send(responseJson) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Respond for request id: \(requestId), error: \(error)")
            }
        }
    }
}
