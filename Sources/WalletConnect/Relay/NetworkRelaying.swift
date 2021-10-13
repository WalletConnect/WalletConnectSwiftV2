
import Foundation

protocol NetworkRelaying {
    var onConnect: (()->())? {get set}
    var onMessage: ((_ topic: String, _ message: String) -> ())? {get set}
    func publish(topic: String, payload: Encodable, completion: @escaping ((Error?)->()))
    /// - returns: request id
    func subscribe(topic: String, completion: @escaping (Error?)->()))
    /// - returns: request id
    func unsubscribe(topic: String, id: String, completion: @escaping ((Error?)->()))
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
