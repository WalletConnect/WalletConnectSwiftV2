
import Foundation
import Combine

protocol WalletConnectRelaying {
    var transportConnectionPublisher: AnyPublisher<Void, Never> {get}
    var clientSynchJsonRpcPublisher: AnyPublisher<WCRequestSubscriptionPayload, Never> {get}
    func publish(topic: String, payload: Encodable) async throws -> Result<JSONRPCResponse<AnyCodable>, JSONRPCError>
    func subscribe(topic: String) async -> Result<String, Error>
    func unsubscribe(topic: String, id: String) async -> Result<Void, Error>
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
    
    
    
    
    
    
    
    func subscribe(topic: String) async -> Result<String, Error> {
        
    }
    
    func unsubscribe(topic: String, id: String) async -> Result<Void, Error> {
        
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
    func subscribe(topic: String) async -> Result<String, Error>
    func unsubscribe(topic: String, id: String) async -> Result<Void, Error>
}

class WakuNetworkRelay: NetworkRelaying {
    func publish(topic: String, message: String) async throws -> String {
        
    }
    
    func subscribe(topic: String) async -> Result<String, Error> {
        <#code#>
    }
    
    func unsubscribe(topic: String, id: String) async -> Result<Void, Error> {
        <#code#>
    }
    
    
}
