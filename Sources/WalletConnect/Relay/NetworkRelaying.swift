
import Foundation
import Combine

protocol NetworkRelaying {
    var onConnect: (()->())? {get set}
    var onMessage: ((_ topic: String, _ message: String) -> ())? {get set}
    /// - returns: request id
    @discardableResult func publish(topic: String, payload: String, completion: @escaping ((Error?)->())) -> Int64
    /// - returns: request id
    @discardableResult func subscribe(topic: String, completion: @escaping (Error?)->()) -> Int64
    /// - returns: request id
    @discardableResult func unsubscribe(topic: String, completion: @escaping ((Error?)->())) -> Int64?
}

class WakuNetworkRelay: NetworkRelaying {
    private typealias SubscriptionRequest = JSONRPCRequest<RelayJSONRPC.SubscriptionParams>
    private typealias SubscriptionResponse = JSONRPCResponse<String>
    private typealias RequestAcknowledgement = JSONRPCResponse<Bool>
    private let concurrentQueue = DispatchQueue(label: "waku relay queue: \(UUID().uuidString)",
                                                attributes: .concurrent)
    var onConnect: (() -> ())?
    
    var onMessage: ((String, String) -> ())?
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
    init(transport: JSONRPCTransporting) {
        self.transport = transport
        setUpBindings()
    }
    
    @discardableResult func publish(topic: String, payload: String, completion: @escaping ((Error?) -> ())) -> Int64 {
        let params = RelayJSONRPC.PublishParams(topic: topic, message: payload, ttl: defaultTtl)
        let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
        let requestJson = try! request.json()
        Logger.debug("Publishing Payload on Topic: \(topic)")
        var cancellable: AnyCancellable!
        transport.send(requestJson) { error in
            if let error = error {
                Logger.debug("Failed to Publish Payload")
                Logger.error(error)
                cancellable.cancel()
                completion(error)
            } else {
                completion(nil)
            }
        }
        cancellable = requestAcknowledgePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
            cancellable.cancel()
                completion(nil)
        }
        return request.id
    }
    
    @discardableResult func subscribe(topic: String, completion: @escaping (Error?) -> ()) -> Int64 {
        Logger.debug("Subscribing on Topic: \(topic)")
        let params = RelayJSONRPC.SubscribeParams(topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.subscribe.rawValue, params: params)
        let requestJson = try! request.json()
        var cancellable: AnyCancellable!
        transport.send(requestJson) { error in
            if let error = error {
                Logger.error("Failed to Subscribe on Topic \(error)")
                cancellable.cancel()
                completion(error)
            } else {
                completion(nil)
            }
        }
        cancellable = subscriptionResponsePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
            cancellable.cancel()
                completion(nil)
        }
        return request.id
    }
    
    @discardableResult func unsubscribe(topic: String, completion: @escaping ((Error?) -> ())) -> Int64? {
        guard let subscriptionId = subscriptions[topic] else {
            completion(WalletConnectError.subscriptionIdNotFound)
            return nil
        }
        Logger.debug("Unsubscribing on Topic: \(topic)")
        let params = RelayJSONRPC.UnsubscribeParams(id: subscriptionId, topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.unsubscribe.rawValue, params: params)
        let requestJson = try! request.json()
        var cancellable: AnyCancellable!
        transport.send(requestJson) { error in
            if let error = error {
                Logger.debug("Failed to Unsubscribe on Topic")
                Logger.error(error)
                cancellable.cancel()
                completion(error)
            } else {
                self.concurrentQueue.async(flags: .barrier) { [weak self] in
                    self?.subscriptions[topic] = nil
                }
                completion(nil)
            }
        }
        cancellable = requestAcknowledgePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
                cancellable.cancel()
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
        } else if let response = tryDecode(JSONRPCError.self, from: payload) {
            Logger.error("Received error message from network, code: \(response.code), message: \(response.message)")
        } else {
            Logger.error("Unexpected response from network")
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
        transport.send(responseJson) { error in
            if let error = error {
                Logger.debug("Failed to Respond for request id: \(requestId)")
                Logger.error(error)
            }
        }
    }
}
