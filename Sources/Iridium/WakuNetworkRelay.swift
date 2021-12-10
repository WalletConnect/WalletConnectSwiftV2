
import Foundation
import Combine
import WalletConnectUtils


public final class WakuNetworkRelay {
    private typealias SubscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>
    private typealias SubscriptionResponse = JSONRPCResponse<String>
    private typealias RequestAcknowledgement = JSONRPCResponse<Bool>
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.waku.relay",
                                                attributes: .concurrent)
    public var onConnect: (() -> ())?
    
    public var onMessage: ((String, String) -> ())?
    private var transport: JSONRPCTransporting
    var subscriptions: [String: String] = [:]
    private let defaultTtl = 6*Time.hour

    private var subscriptionResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {
        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let subscriptionResponsePublisherSubject = PassthroughSubject<JSONRPCResponse<String>, Never>()
    private var requestAcknowledgePublisher: AnyPublisher<JSONRPCResponse<Bool>, Never> {
        requestAcknowledgePublisherSubject.eraseToAnyPublisher()
    }
    private let requestAcknowledgePublisherSubject = PassthroughSubject<JSONRPCResponse<Bool>, Never>()
    private let logger: ConsoleLogging
    
    init(transport: JSONRPCTransporting,
         logger: ConsoleLogging) {
        self.logger = logger
        self.transport = transport
        setUpBindings()
    }
    
    public convenience init(logger: ConsoleLogging, url: URL) {
        self.init(transport: JSONRPCTransport(url: url), logger: logger)
    }
    
    public func connect() {
        transport.connect()
    }
    
    public func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
        transport.disconnect(closeCode: closeCode)
    }
    
    @discardableResult public func publish(topic: String, payload: String, completion: @escaping ((Error?) -> ())) -> Int64 {
        let params = RelayJSONRPC.PublishParams(topic: topic, message: payload, ttl: defaultTtl)
        let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
        let requestJson = try! request.json()
        logger.debug("waku: Publishing Payload on Topic: \(topic)")
        var cancellable: AnyCancellable?
        transport.send(requestJson) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Publish Payload")
                self?.logger.error(error)
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
        transport.send(requestJson) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to Subscribe on Topic \(error)")
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
//            completion(WalletConnectError.internal(.subscriptionIdNotFound))
            //TODO - complete with iridium error
            return nil
        }
        logger.debug("waku: Unsubscribing on Topic: \(topic)")
        let params = RelayJSONRPC.UnsubscribeParams(id: subscriptionId, topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.unsubscribe.rawValue, params: params)
        let requestJson = try! request.json()
        var cancellable: AnyCancellable?
        transport.send(requestJson) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Unsubscribe on Topic")
                self?.logger.error(error)
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
        transport.onMessage = { [weak self] payload in
            self?.handlePayloadMessage(payload)
        }
        transport.onConnect = { [unowned self] in
            self.onConnect?()
        }
    }
    
    private func handlePayloadMessage(_ payload: String) {
        if let request = tryDecode(SubscriptionRequest.self, from: payload),
           request.method == RelayJSONRPC.Method.subscription.rawValue {
            onMessage?(request.params.data.topic, request.params.data.message)
            acknowledgeSubscription(requestId: request.id)
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
        let response = JSONRPCResponse(id: requestId, result: true)
        let responseJson = try! response.json()
        transport.send(responseJson) { [weak self] error in
            if let error = error {
                self?.logger.debug("Failed to Respond for request id: \(requestId)")
                self?.logger.error(error)
            }
        }
    }
    
    static public func makeRelayUrl(host: String, apiKey: String) -> URL {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = host
        components.queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        return components.url!
    }
}
