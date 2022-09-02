import Foundation
import Combine
import JSONRPC
import WalletConnectRelay
import WalletConnectKMS
import WalletConnectNetworking

public class NetworkingInteractorMock: NetworkInteracting {

    private(set) var subscriptions: [String] = []

    public let socketConnectionStatusPublisherSubject = PassthroughSubject<SocketConnectionStatus, Never>()
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    private let requestPublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest), Never>()
    private let responsePublisherSubject = PassthroughSubject<(topic: String, request: RPCRequest, response: RPCResponse), Never>()

    private var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest), Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }

    private var responsePublisher: AnyPublisher<(topic: String, request: RPCRequest, response: RPCResponse), Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }

    public func requestSubscription<Request: Codable>(on request: NetworkRequest) -> AnyPublisher<RequestSubscriptionPayload<Request>, Never> {
        return requestPublisher
            .filter { $0.request.method == request.method }
            .compactMap { topic, rpcRequest in
                guard let id = rpcRequest.id, let request = try? rpcRequest.params?.get(Request.self) else { return nil }
                return RequestSubscriptionPayload(id: id, topic: topic, request: request)
            }
            .eraseToAnyPublisher()
    }

    public func responseSubscription<Request: Codable, Response: Codable>(on request: NetworkRequest) -> AnyPublisher<ResponseSubscriptionPayload<Request, Response>, Never> {
        return responsePublisher
            .filter { $0.request.method == request.method }
            .compactMap { topic, rpcRequest, rpcResponce in
                guard
                    let id = rpcRequest.id,
                    let request = try? rpcRequest.params?.get(Request.self),
                    let response = try? rpcResponce.result?.get(Response.self) else { return nil }
                return ResponseSubscriptionPayload(id: id, topic: topic, request: request, response: response)
            }
            .eraseToAnyPublisher()
    }

    public func subscribe(topic: String) async throws {
        subscriptions.append(topic)
    }

    func didSubscribe(to topic: String) -> Bool {
         subscriptions.contains { $0 == topic }
    }

    public func unsubscribe(topic: String) {

    }

    public func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {

    }

    public func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {

    }

    public func respondSuccess(topic: String, requestId: RPCID, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {

    }

    public func respondError(topic: String, requestId: RPCID, tag: Int, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws {

    }

    public func requestNetworkAck(_ request: RPCRequest, topic: String, tag: Int) async throws {

    }
}
