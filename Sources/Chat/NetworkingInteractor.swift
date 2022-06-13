
import Foundation
import Combine
import WalletConnectRelay
import WalletConnectUtils

protocol NetworkInteracting {
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {get}
    var responsePublisher: AnyPublisher<ChatResponse, Never> {get}
    func subscribe(topic: String) async throws
    func requestUnencrypted(_ request: ChatRequest, topic: String) async throws
    func request(_ request: ChatRequest, topic: String) async throws
    func respond(topic: String, response: JsonRpcResult) async throws

}

class NetworkingInteractor: NetworkInteracting {
    enum Error: Swift.Error {
        case failedToInitialiseMethodFromRecord
    }
    //TODO - must be injectible
    private let jsonRpcHistory: JsonRpcHistory<ChatRequest>
    private let serializer: Serializing
    private let relayClient: RelayClient
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    private let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    
    var responsePublisher: AnyPublisher<ChatResponse, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }
    private let responsePublisherSubject = PassthroughSubject<ChatResponse, Never>()

    init(relayClient: RelayClient,
         serializer: Serializing) {
        self.relayClient = relayClient
        self.serializer = serializer
        
        relayClient.onMessage = { [unowned self] topic, message in
            manageSubscription(topic, message)
        }
    }
    
    func requestUnencrypted(_ request: ChatRequest, topic: String) async throws {
        let message = try! request.json()
        try await relayClient.publish(topic: topic, payload: message)
    }
    
    func request(_ request: ChatRequest, topic: String) async throws {
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
        if let deserializedJsonRpcRequest: ChatRequest = serializer.tryDeserialize(topic: topic, message: message) {
            handleWCRequest(topic: topic, request: deserializedJsonRpcRequest)
        } else if let decodedJsonRpcRequest: ChatRequest = tryDecodeRequest(message: message) {
            handleWCRequest(topic: topic, request: decodedJsonRpcRequest)

        } else if let deserializedJsonRpcResponse: JSONRPCResponse<AnyCodable> = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcResponse(response: deserializedJsonRpcResponse)
        } else if let deserializedJsonRpcError: JSONRPCErrorResponse = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcErrorResponse(response: deserializedJsonRpcError)
        } else {
            print("Warning: WalletConnect Relay - Received unknown object type from networking relay")
        }
    }
    
    
    private func tryDecodeRequest(message: String) -> ChatRequest? {
        guard let messageData = message.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(ChatRequest.self, from: messageData)
    }
    
    private func handleWCRequest(topic: String, request: ChatRequest) {
        let payload = RequestSubscriptionPayload(topic: topic, request: request)
        requestPublisherSubject.send(payload)
    }
    
    private func handleJsonRpcResponse(response: JSONRPCResponse<AnyCodable>) {
        do {
            let record = try jsonRpcHistory.resolve(response: JsonRpcResult.response(response))
            guard let method = ChatRequest.Method(rawValue: record.request.method) else {
                throw Error.failedToInitialiseMethodFromRecord
            }
            let params = try record.request.params.get(ChatRequest.Params.self)
            
            let chatResponse = ChatResponse(
                topic: record.topic,
                requestMethod: method,
                requestParams: params,
                result: JsonRpcResult.response(response))
            responsePublisherSubject.send(chatResponse)
        } catch {
            
        }
    }
    
    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
        //todo
    }
    
}
