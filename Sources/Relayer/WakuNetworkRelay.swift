
import Foundation
import Combine
import WalletConnectUtils


public final class WakuNetworkRelay {
    enum RelyerError: Error {
        case subscriptionIdNotFound
    }
    private typealias SubscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>
    private typealias SubscriptionResponse = JSONRPCResponse<String>
    private typealias RequestAcknowledgement = JSONRPCResponse<Bool>
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.relayer",
                                                attributes: .concurrent)
    public var onConnect: (() -> ())?
    let jsonRpcSubscriptionsHistory: JsonRpcHistory<RelayJSONRPC.SubscriptionParams>
    public var onMessage: ((String, String) -> ())?
    private var dispatcher: Dispatching
    var subscriptions: [String: String] = [:]
    let defaultTtl = 6*Time.hour

    private var subscriptionResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {
        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let subscriptionResponsePublisherSubject = PassthroughSubject<JSONRPCResponse<String>, Never>()
    private var requestAcknowledgePublisher: AnyPublisher<JSONRPCResponse<Bool>, Never> {
        requestAcknowledgePublisherSubject.eraseToAnyPublisher()
    }
    private let requestAcknowledgePublisherSubject = PassthroughSubject<JSONRPCResponse<Bool>, Never>()
    private let logger: ConsoleLogging
    
    init(dispatcher: Dispatching,
         logger: ConsoleLogging,
         keyValueStorage: KeyValueStorage,
         uniqueIdentifier: String) {
        self.logger = logger
        self.dispatcher = dispatcher
        let historyIdentifier = "com.walletconnect.sdk.\(uniqueIdentifier).relayer.subscription_json_rpc_record"
        self.jsonRpcSubscriptionsHistory = JsonRpcHistory<RelayJSONRPC.SubscriptionParams>(logger: logger, keyValueStore: KeyValueStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: historyIdentifier))
        setUpBindings()
    }
    
    public convenience init(logger: ConsoleLogging,
                            url: URL,
                            keyValueStorage: KeyValueStorage,
                            uniqueIdentifier: String) {
        let socketConnectionObserver = SocketConnectionObserver()
        let urlSession = URLSession(configuration: .default, delegate: socketConnectionObserver, delegateQueue: OperationQueue())
        let socket = WebSocketSession(session: urlSession)
        let dispatcher = Dispatcher(url: url, socket: socket, socketConnectionObserver: socketConnectionObserver)
        self.init(dispatcher: dispatcher,
                  logger: logger,
                  keyValueStorage: keyValueStorage,
                  uniqueIdentifier: uniqueIdentifier)
    }
    
    public func connect() {
        dispatcher.connect()
    }
    
    public func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
        dispatcher.disconnect(closeCode: closeCode)
    }
    
    @discardableResult public func publish(topic: String, payload: String, completion: @escaping ((Error?) -> ())) -> Int64 {
        let params = RelayJSONRPC.PublishParams(topic: topic, message: payload, ttl: defaultTtl)
        let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
        let requestJson = try! request.json()
        logger.debug("waku: Publishing Payload on Topic: \(topic)")
        var cancellable: AnyCancellable?
        dispatcher.send(requestJson) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Publish Payload, error: \(error)")
                cancellable?.cancel()
                completion(error)
            }
        }
        cancellable = requestAcknowledgePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
            cancellable?.cancel()
                completion(nil)
        }
        return request.id
    }
    
    @discardableResult public func subscribe(topic: String, completion: @escaping (Error?) -> ()) -> Int64 {
        logger.debug("waku: Subscribing on Topic: \(topic)")
        let params = RelayJSONRPC.SubscribeParams(topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.subscribe.rawValue, params: params)
        let requestJson = try! request.json()
        var cancellable: AnyCancellable?
        dispatcher.send(requestJson) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Subscribe on Topic \(error)")
                cancellable?.cancel()
                completion(error)
            } else {
                completion(nil)
            }
        }
        cancellable = subscriptionResponsePublisher
            .filter {$0.id == request.id}
            .sink { [weak self] (subscriptionResponse) in
            cancellable?.cancel()
                self?.subscriptions[topic] = subscriptionResponse.result
                completion(nil)
        }
        return request.id
    }
    
    @discardableResult public func unsubscribe(topic: String, completion: @escaping ((Error?) -> ())) -> Int64? {
        guard let subscriptionId = subscriptions[topic] else {
            completion(RelyerError.subscriptionIdNotFound)
            return nil
        }
        logger.debug("waku: Unsubscribing on Topic: \(topic)")
        let params = RelayJSONRPC.UnsubscribeParams(id: subscriptionId, topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.unsubscribe.rawValue, params: params)
        let requestJson = try! request.json()
        var cancellable: AnyCancellable?
        jsonRpcSubscriptionsHistory.delete(topic: topic)
        dispatcher.send(requestJson) { [weak self] error in
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
        cancellable = requestAcknowledgePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
                cancellable?.cancel()
                completion(nil)
            }
        return request.id
    }

    private func setUpBindings() {
        dispatcher.onMessage = { [weak self] payload in
            self?.handlePayloadMessage(payload)
        }
        dispatcher.onConnect = { [unowned self] in
            self.onConnect?()
        }
    }
    
    private func handlePayloadMessage(_ payload: String) {
        if let request = tryDecode(SubscriptionRequest.self, from: payload),
           request.method == RelayJSONRPC.Method.subscription.rawValue {
            do {
                try jsonRpcSubscriptionsHistory.set(topic: request.params.data.topic, request: request)
                onMessage?(request.params.data.topic, request.params.data.message)
                acknowledgeSubscription(requestId: request.id)
            } catch {
                logger.info("Relayer Info: Json Rpc Duplicate Detected")
            }
        } else if let response = tryDecode(RequestAcknowledgement.self, from: payload) {
            requestAcknowledgePublisherSubject.send(response)
        } else if let response = tryDecode(SubscriptionResponse.self, from: payload) {
            subscriptionResponsePublisherSubject.send(response)
        } else if let response = tryDecode(JSONRPCErrorResponse.self, from: payload) {
            logger.error("Received error message from waku network, code: \(response.error.code), message: \(response.error.message)")
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
    
    private func acknowledgeSubscription(requestId: Int64) {
        let response = JSONRPCResponse(id: requestId, result: AnyCodable(true))
        let responseJson = try! response.json()
        _ = try? jsonRpcSubscriptionsHistory.resolve(response: JsonRpcResponseTypes.response(response))
        dispatcher.send(responseJson) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Respond for request id: \(requestId), error: \(error)")
            }
        }
    }
    
    static public func makeRelayUrl(host: String, projectId: String) -> URL {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = host
        components.queryItems = [URLQueryItem(name: "projectId", value: projectId)]
        return components.url!
    }
}
