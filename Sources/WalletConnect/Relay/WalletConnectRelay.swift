
import Foundation
import Combine

protocol WalletConnectRelaying {
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    func publish(topic: String, payload: Encodable) async throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCError>
    func subscribe(topic: String)
    func unsubscribe(topic: String, id: String)
}

class WalletConnectRelay: WalletConnectRelaying {
    private let networkRelayer: NetworkRelaying
    private let jsonRpcSerialiser: JSONRPCSerialising
    private let crypto: Crypto
    
    var transportConnectionPublisher: AnyPublisher<Void, Never>
    
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never>
    
    init(networkRelayer: NetworkRelaying = WakuNetworkRelay(),
         jsonRpcSerialiser: JSONRPCSerialising = JSONRPCSerialiser(),
         crypto: Crypto) {
        self.networkRelayer = networkRelayer
        self.jsonRpcSerialiser = jsonRpcSerialiser
        self.crypto = crypto
    }
    
    func publish(topic: String, payload: Encodable) async throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCError> {
        let message = try serialise(topic: topic, jsonRpc: payload)
        let receivedMessage = try await networkRelayer.publish(topic: topic, message: message)
        return try deserialiseJsonRpc(topic: topic, message: receivedMessage)
    }
    
    
    
    
    
    
    
    func subscribe(topic: String)  {
        do {
            await try networkRelayer.subscribe(topic: topic)
        } catch {
            Logger.error(error)
        }
    }
    
    func unsubscribe(topic: String, id: String) {
        do {
            try await networkRelayer.unsubscribe(topic: topic, id: id)
        } catch {
            Logger.error(error)
        }
    }
    
    
    
    private func serialise(topic: String, jsonRpc: Encodable) throws -> String {
        let messageJson = try jsonRpc.json()
        var message: String
        if let agreementKeys = crypto.getAgreementKeys(for: topic) {
            message = try jsonRpcSerialiser.serialise(json: messageJson, agreementKeys: agreementKeys)
        } else {
            message = messageJson.toHexEncodedString(uppercase: false)
        }
        return message
    }
    
    private func deserialiseJsonRpc(topic: String, message: String) throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCError> {
        guard let agreementKeys = crypto.getAgreementKeys(for: topic) else {
            throw WalletConnectError.keyNotFound
        }
        if let jsonrpcResponse: JSONRPCResponse<AnyCodable> = try? jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret) {
            return .success(jsonrpcResponse)
        } else if let jsonrpcError: JSONRPCError = try? jsonRpcSerialiser.deserialise(message: message, symmetricKey: agreementKeys.sharedSecret) {
            return .failure(jsonrpcError)
        }
        throw WalletConnectError.deserialisationFailed
    }
}

protocol NetworkRelaying {
    func publish(topic: String, message: String) async throws -> String
    func subscribe(topic: String) async throws
    func unsubscribe(topic: String, id: String) async throws
}

class WakuNetworkRelay: NetworkRelaying {
    private var transport: JSONRPCTransporting
    var subscriptions: [String: String] = [:]
    private var subscriptionResponsePublisher: AnyPublisher<JSONRPCResponse<String>, Never> {
        subscriptionResponsePublisherSubject.eraseToAnyPublisher()
    }
    private let subscriptionResponsePublisherSubject = PassthroughSubject<JSONRPCResponse<String>, Never>()
    
    init(transport: JSONRPCTransporting) {
        self.transport = transport
//        setUpBindings()
    }
    
    func publish(topic: String, message: String) async throws -> String {
        
    }
    
    func subscribe(topic: String) async throws {
        let params = RelayJSONRPC.SubscribeParams(topic: topic)
        let request = JSONRPCRequest(method: RelayJSONRPC.Method.subscribe.rawValue, params: params)
        let requestJson = try request.json()
        var cancellable: AnyCancellable!
        if let error = await transport.send(requestJson) {
            Logger.debug("Failed to Subscribe on Topic")
            Logger.error(error)
            cancellable.cancel()
            throw error
        }
        cancellable = subscriptionResponsePublisher
            .filter {$0.id == request.id}
            .sink { [weak self] (subscriptionResponse) in
            cancellable.cancel()
                self?.subscriptions[topic] = subscriptionId
        }
    }
    
    func unsubscribe(topic: String, id: String) async throws {
        <#code#>
    }
    
    
}
