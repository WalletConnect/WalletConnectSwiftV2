
import Foundation
import Combine
import WalletConnectRelay
import WalletConnectUtils

protocol NetworkInteracting {
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {get}
    var responsePublisher: AnyPublisher<ChatResponse, Never> {get}
    func subscribe(topic: String) async throws
    func requestUnencrypted(_ request: JSONRPCRequest<ChatRequestParams>, topic: String) async throws
    func request(_ request: JSONRPCRequest<ChatRequestParams>, topic: String) async throws
    func respond(topic: String, response: JsonRpcResult) async throws

}

class NetworkingInteractor: NetworkInteracting {
    enum Error: Swift.Error {
        case failedToInitialiseMethodFromRecord
    }
    private let jsonRpcHistory: JsonRpcHistory<ChatRequestParams>
    private let serializer: Serializing
    private let relayClient: RelayClient
    private let logger: ConsoleLogging
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    private let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    
    var responsePublisher: AnyPublisher<ChatResponse, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }
    private let responsePublisherSubject = PassthroughSubject<ChatResponse, Never>()
    
    init(relayClient: RelayClient,
         serializer: Serializing,
         logger: ConsoleLogging,
         jsonRpcHistory: JsonRpcHistory<ChatRequestParams>
    ) {
        self.relayClient = relayClient
        self.serializer = serializer
        self.jsonRpcHistory = jsonRpcHistory
        self.logger = logger
        relayClient.onMessage = { [unowned self] topic, message in
            manageSubscription(topic, message)
        }
    }
    
    // TODO - remove the method
    func requestUnencrypted(_ request: JSONRPCRequest<ChatRequestParams>, topic: String) async throws {
        try jsonRpcHistory.set(topic: topic, request: request)
        let message = try! request.json()
        try await relayClient.publish(topic: topic, payload: message)
    }
    
    func request(_ request: JSONRPCRequest<ChatRequestParams>, topic: String) async throws {
        try jsonRpcHistory.set(topic: topic, request: request)
        let message = try! serializer.serialize(topic: topic, encodable: request)
        try await relayClient.publish(topic: topic, payload: message)
    }
    
    func respond(topic: String, response: JsonRpcResult) async throws {
        let message = try serializer.serialize(topic: topic, encodable: response.value)
        try await relayClient.publish(topic: topic, payload: message, prompt: false)
    }
    
    func subscribe(topic: String) async throws {
        try await relayClient.subscribe(topic: topic)
    }
    
    private func manageSubscription(_ topic: String, _ message: String) {
        if let deserializedJsonRpcRequest: JSONRPCRequest<ChatRequestParams> = serializer.tryDeserialize(topic: topic, message: message) {
            handleWCRequest(topic: topic, request: deserializedJsonRpcRequest)
        } else if let decodedJsonRpcRequest: JSONRPCRequest<ChatRequestParams> = tryDecodeRequest(message: message) {
            handleWCRequest(topic: topic, request: decodedJsonRpcRequest)

        } else if let deserializedJsonRpcResponse: JSONRPCResponse<AnyCodable> = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcResponse(response: deserializedJsonRpcResponse)
        } else if let deserializedJsonRpcError: JSONRPCErrorResponse = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcErrorResponse(response: deserializedJsonRpcError)
        } else {
            print("Warning: WalletConnect Relay - Received unknown object type from networking relay")
        }
    }
    
    
    private func tryDecodeRequest(message: String) -> JSONRPCRequest<ChatRequestParams>? {
        guard let messageData = message.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(JSONRPCRequest<ChatRequestParams>.self, from: messageData)
    }
    
    private func handleWCRequest(topic: String, request: JSONRPCRequest<ChatRequestParams>) {
        let payload = RequestSubscriptionPayload(topic: topic, request: request)
        requestPublisherSubject.send(payload)
    }
    
    private func handleJsonRpcResponse(response: JSONRPCResponse<AnyCodable>) {
        do {
            let record = try jsonRpcHistory.resolve(response: JsonRpcResult.response(response))
            let params = try record.request.params.get(ChatRequestParams.self)
            let chatResponse = ChatResponse(
                topic: record.topic,
                requestMethod: record.request.method,
                requestParams: params,
                result: JsonRpcResult.response(response))
            responsePublisherSubject.send(chatResponse)
        } catch {
            logger.debug("Handle json rpc response error: \(error)")
        }
    }
    
    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
        //todo
    }
    
}
