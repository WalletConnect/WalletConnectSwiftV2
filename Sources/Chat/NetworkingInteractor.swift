
import Foundation
import Combine
import Relayer
import WalletConnectUtils


class NetworkingInteractor {
    let networkRelayer: Relayer
    private let serializer: Serializing
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    private let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    
    var responsePublisher: AnyPublisher<MessagingResponse, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }
    private let responsePublisherSubject = PassthroughSubject<MessagingResponse, Never>()

    init(relayClient: Relayer,
         serializer: Serializing) {
        self.networkRelayer = relayClient
        self.serializer = serializer
        
        networkRelayer.onMessage = { [unowned self] topic, message in
            manageSubscription(topic, message)
        }
    }
    
    func request(_ request: MessagingRequest, topic: String) {
        let message = try! serializer.serialize(topic: topic, encodable: request)
                networkRelayer.publish(topic: topic, payload: message) {error in
                    print(error)
        }
    }
    
    func subscribe(topic: String)  {
        networkRelayer.subscribe(topic: topic) { [weak self] error in
            if let error = error {
                print(error)
            }
        }
    }
    
    private func manageSubscription(_ topic: String, _ message: String) {
        if let deserializedJsonRpcRequest: MessagingRequest = serializer.tryDeserialize(topic: topic, message: message) {
            handleWCRequest(topic: topic, request: deserializedJsonRpcRequest)
        } else if let deserializedJsonRpcResponse: JSONRPCResponse<AnyCodable> = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcResponse(response: deserializedJsonRpcResponse)
        } else if let deserializedJsonRpcError: JSONRPCErrorResponse = serializer.tryDeserialize(topic: topic, message: message) {
            handleJsonRpcErrorResponse(response: deserializedJsonRpcError)
        } else {
            print("Warning: WalletConnect Relay - Received unknown object type from networking relay")
        }
    }
    
    
    
    
    private func handleWCRequest(topic: String, request: MessagingRequest) {
        do {
            let payload = RequestSubscriptionPayload(topic: topic, request: request)
            requestPublisherSubject.send(payload)
        } catch {
            print(error)
        }
    }
    
    private func handleJsonRpcResponse(response: JSONRPCResponse<AnyCodable>) {
        //todo
    }
    
    private func handleJsonRpcErrorResponse(response: JSONRPCErrorResponse) {
        //todo
    }
    
}
