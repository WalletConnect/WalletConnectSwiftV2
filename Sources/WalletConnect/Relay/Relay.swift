
import Foundation
import Combine

protocol Relaying {
    /// - returns: request id
    func publish(topic: String, payload: Encodable, completion: @escaping ((Result<Void, Error>)->())) throws -> Int64
    /// - returns: request id
    func subscribe(topic: String, completion: @escaping ((Result<String, Error>)->())) throws -> Int64
    /// - returns: request id
    func unsubscribe(topic: String, id: String, completion: @escaping ((Result<Void, Error>)->())) throws -> Int64
}

class Relay: Relaying {
    // ttl for waku network to persist message for comunitationg client in case request is not acknowledged
    private let defaultTtl = 6*Time.hour
    private let jsonRpcSerialiser: JSONRPCSerialising
    private var transport: JSONRPCTransporting
    private let crypto: Crypto
    private var subscriptionResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {
        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let subscriptionResponsePublisherSubject = PassthroughSubject<JSONRPCResponse<String>, Never>()
    private var requestAcknowledgePublisher: AnyPublisher<JSONRPCResponse<Bool>, Never> {
        requestAcknowledgePublisherSubject.eraseToAnyPublisher()
    }
    private let requestAcknowledgePublisherSubject = PassthroughSubject<JSONRPCResponse<Bool>, Never>()
    var clientSynchJsonRpcPublisher: AnyPublisher<ClientSynchJSONRPC, Never> {
        clientSynchJsonRpcPublisherSubject.eraseToAnyPublisher()
    }
    private let clientSynchJsonRpcPublisherSubject = PassthroughSubject<ClientSynchJSONRPC, Never>()
    
    init(jsonRpcSerialiser: JSONRPCSerialising = JSONRPCSerialiser(),
         transport: JSONRPCTransporting,
         crypto: Crypto) {
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.transport = transport
        self.crypto = crypto
        setUpTransport()
    }

    func publish(topic: String, payload: Encodable, completion: @escaping ((Result<Void, Error>)->())) throws -> Int64 {
        let messageJson = try payload.json()
        var message: String
        if let agreementKeys = crypto.getAgreementKeys(for: topic) {
            message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
        } else {
            message = messageJson.toHexEncodedString(uppercase: false)
        }
        let params = RelayJSONRPC.PublishParams(topic: topic, message: message, ttl: defaultTtl)
        let request = JSONRPCRequest<RelayJSONRPC.PublishParams>(method: RelayJSONRPC.Method.publish.rawValue, params: params)
        let requestJson = try request.json()
        Logger.debug("Publishing Payload on Topic: \(topic)")
        var cancellable: AnyCancellable!
        transport.send(requestJson) { error in
            if let error = error {
                Logger.debug("Failed to Publish Payload")
                Logger.error(error)
                cancellable.cancel()
                completion(.failure(error))
            }
        }
        cancellable = requestAcknowledgePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
            cancellable.cancel()
                completion(.success(()))
        }
        return request.id
    }
    
    func subscribe(topic: String, completion: @escaping ((Result<String, Error>)->())) throws -> Int64 {
        Logger.debug("Subscribing on Topic: \(topic)")
        let params = RelayJSONRPC.SubscribeParams(topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.subscribe.rawValue, params: params)
        let requestJson = try request.json()
        var cancellable: AnyCancellable!
        transport.send(requestJson) { error in
            if let error = error {
                Logger.debug("Failed to Subscribe on Topic")
                Logger.error(error)
                cancellable.cancel()
                completion(.failure(error))
            }
        }
        cancellable = subscriptionResponsePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
            cancellable.cancel()
                completion(.success(subscriptionResponse.result))
        }
        return request.id
    }
    
    func unsubscribe(topic: String, id: String, completion: @escaping ((Result<Void, Error>)->())) throws -> Int64 {
        Logger.debug("Unsubscribing on Topic: \(topic)")
        let params = RelayJSONRPC.UnsubscribeParams(id: id, topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.unsubscribe.rawValue, params: params)
        let requestJson = try request.json()
        var cancellable: AnyCancellable!
        transport.send(requestJson) { error in
            if let error = error {
                Logger.debug("Failed to Unsubscribe on Topic")
                Logger.error(error)
                cancellable.cancel()
                completion(.failure(error))
            }
        }
        cancellable = requestAcknowledgePublisher
            .filter {$0.id == request.id}
            .sink { (subscriptionResponse) in
            cancellable.cancel()
                completion(.success(()))
        }
        return request.id
    }

    private func setUpTransport() {
        transport.onMessage = { [unowned self] payload in
            self.onPayload(payload)
        }
    }

    private func onPayload(_ payload: String) {
        if let request = getClientSubscriptionRequest(from: payload) {
            manageSubscriptionRequest(request)
        } else if let response = getRequestAcknowledgement(from: payload) {
            requestAcknowledgePublisherSubject.send(response)
        } else if let response = getNetworkSubscriptionResponse(from: payload) {
            subscriptionResponsePublisherSubject.send(response)
        } else if let response = getErrorResponse(from: payload) {
            Logger.error("Received error message from network, code: \(response.code), message: \(response.message)")
        } else {
            Logger.error("Unexpected response from network")
        }
    }
    
    private func getClientSubscriptionRequest(from payload: String) -> JSONRPCRequest<RelayJSONRPC.SubscriptionParams>? {
        if let data = payload.data(using: .utf8),
           let request = try? JSONDecoder().decode(JSONRPCRequest<RelayJSONRPC.SubscriptionParams>.self, from: data),
           request.method == RelayJSONRPC.Method.subscription.rawValue {
            return request
        } else {
            return nil
        }
    }
    
    private func getNetworkSubscriptionResponse(from payload: String) -> JSONRPCResponse<String>? {
        if let data = payload.data(using: .utf8),
           let response = try? JSONDecoder().decode(JSONRPCResponse<String>.self, from: data) {
            return response
        } else {
            return nil
        }
    }
    
    private func getRequestAcknowledgement(from payload: String) -> JSONRPCResponse<Bool>? {
        if let data = payload.data(using: .utf8),
           let response = try? JSONDecoder().decode(JSONRPCResponse<Bool>.self, from: data) {
            return response
        } else {
            return nil
        }
    }
    
    private func getErrorResponse(from payload: String) -> JSONRPCError? {
        if let data = payload.data(using: .utf8),
           let request = try? JSONDecoder().decode(JSONRPCError.self, from: data) {
            return request
        } else {
            return nil
        }
    }
    
    private func manageSubscriptionRequest(_ request: JSONRPCRequest<RelayJSONRPC.SubscriptionParams>) {
        let topic = request.params.data.topic
        if let agreementKeys = crypto.getAgreementKeys(for: topic) {
            let message = request.params.data.message
            do {
                let deserialisedJsonRpcRequest = try jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret)
                clientSynchJsonRpcPublisherSubject.send(deserialisedJsonRpcRequest)
                let response = JSONRPCResponse(id: request.id, result: true)
                let responseJson = try response.json()
                transport.send(responseJson) { error in
                    if let error = error {
                        Logger.debug("Failed to Respond for request id: \(request.id)")
                        Logger.error(error)
                    }
                }
            } catch {
                Logger.error(error)
            }
        } else {
            Logger.debug("Did not find key associated with topic: \(topic)")
        }
    }
}
