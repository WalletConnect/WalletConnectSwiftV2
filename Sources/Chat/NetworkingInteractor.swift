
import Foundation
import Combine
import WalletConnectRelay
import WalletConnectUtils

protocol NetworkInteracting {
    func subscribe(topic: String) async throws 
}

class NetworkingInteractor: NetworkInteracting {
    let relayClient: RelayClient
    private let serializer: Serializing
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
    
    func requestUnencrypted(_ request: ChatRequest, topic: String) {
        let message = try! request.json()
        relayClient.publish(topic: topic, payload: message) {error in
//            print(error)
        }
    }
    
    func request(_ request: ChatRequest, topic: String) {
        let message = try! serializer.serialize(topic: topic, encodable: request)
        relayClient.publish(topic: topic, payload: message) {error in
//            print(error)
        }
    }
    
    func respond(topic: String, response: JsonRpcResult) {
        do {
            let message = try serializer.serialize(topic: topic, encodable: response.value)
            logger.debug("Responding....topic: \(topic)")
            relayClient.publish(topic: topic, payload: message, prompt: false) { error in
                completion(error)
            }
        } catch WalletConnectError.internal(.jsonRpcDuplicateDetected) {
            logger.info("Info: Json Rpc Duplicate Detected")
        } catch {
            completion(error)
        }
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
        //todo
    }
    
    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
        //todo
    }
    
}
