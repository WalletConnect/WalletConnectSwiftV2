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

    public var messagePublisher: AnyPublisher<(topic: String, message: String, publishedAt: Date), Never> {
        messagePublisherSubject.eraseToAnyPublisher()
    }

    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        dispatcher.socketConnectionStatusPublisher
    }

    private let messagePublisherSubject = PassthroughSubject<(topic: String, message: String, publishedAt: Date), Never>()

    private let subscriptionResponsePublisherSubject = PassthroughSubject<(RPCID?, [String]), Never>()
    private var subscriptionResponsePublisher: AnyPublisher<(RPCID?, [String]), Never> {
        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
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
        rpcHistory: RPCHistory,
        clientIdStorage: ClientIdStoring
    ) {
        self.logger = logger
        self.dispatcher = dispatcher
        self.rpcHistory = rpcHistory
        self.clientIdStorage = clientIdStorage
        setUpBindings()
    }

    private func setUpBindings() {
        dispatcher.onMessage = { [weak self] payload in
            self?.handlePayloadMessage(payload)
        }
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
            .asRPCRequest()
        let message = try request.asJSONEncodedString()
        logger.debug("[RelayClient]: Publishing payload on topic: \(topic)")
        try await dispatcher.protectedSend(message)
    }

    public func subscribe(topic: String) async throws {
        logger.debug("[RelayClient]: Subscribing to topic: \(topic)")
        let rpc = Subscribe(params: .init(topic: topic))
        let request = rpc
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        try await dispatcher.protectedSend(message)
        observeSubscription(requestId: request.id!, topics: [topic])
    }

    public func batchSubscribe(topics: [String]) async throws {
        guard !topics.isEmpty else { return }
        logger.debug("[RelayClient]: Subscribing to topics: \(topics)")
        let rpc = BatchSubscribe(params: .init(topics: topics))
        let request = rpc
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        try await dispatcher.protectedSend(message)
        observeSubscription(requestId: request.id!, topics: topics)
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
        logger.debug("[RelayClient]: Unsubscribing from topic: \(topic)")
        let rpc = Unsubscribe(params: .init(id: subscriptionId, topic: topic))
        let request = rpc
            .asRPCRequest()
        let message = try! request.asJSONEncodedString()
        rpcHistory.deleteAll(forTopic: topic)
        dispatcher.protectedSend(message) { [weak self] error in
            if let error = error {
                self?.logger.debug("[RelayClient]:Failed to unsubscribe from topic")
                completion(error)
            } else {
                self?.concurrentQueue.async(flags: .barrier) {
                    self?.subscriptions[topic] = nil
                }
                completion(nil)
            }
        }
    }


    private func observeSubscription(requestId: RPCID, topics: [String]) {
        var cancellable: AnyCancellable?
        cancellable = subscriptionResponsePublisher
            .filter { $0.0 == requestId }
            .sink { [unowned self] (_, subscriptionIds) in
                cancellable?.cancel()
                concurrentQueue.async(flags: .barrier) { [unowned self] in
                    logger.debug("[RelayClient]: Subscribed to topics: \(topics)")
                    guard topics.count == subscriptionIds.count else {
                        logger.warn("RelayClient: Number of topics in (batch)subscribe does not match number of subscriptions")
                        return
                    }
                    for i in 0..<topics.count {
                        subscriptions[topics[i]] = subscriptionIds[i]
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
                    logger.debug("[RelayClient]: received message: \(params.data.message) on topic: \(params.data.topic)")
                    messagePublisherSubject.send((params.data.topic, params.data.message, params.data.publishedAt))
                } catch {
                    logger.error("[RelayClient]: RPC History 'set()' error: \(error)")
                }
            } else {
                logger.error("[RelayClient]: Unexpected request from network")
            }
        } else if let response = tryDecode(RPCResponse.self, from: payload) {
            switch response.outcome {
            case .response(let anyCodable):
                if let subscriptionId = try? anyCodable.get(String.self) {
                    subscriptionResponsePublisherSubject.send((response.id, [subscriptionId]))
                } else if let subscriptionIds = try? anyCodable.get([String].self) {
                    subscriptionResponsePublisherSubject.send((response.id, subscriptionIds))
                }
            case .error(let rpcError):
                logger.error("[RelayClient]: Received RPC error from relay network: \(rpcError)")
            }
        } else {
            logger.error("[RelayClient]: Unexpected request/response from network")
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
                logger.debug("[RelayClient]: Failed to dispatch response: \(response), error: \(error)")
            } else {
                do {
                    try rpcHistory.resolve(response)
                } catch {
                    logger.debug("[RelayClient]: \(error)")
                }
            }
        }
    }
}
