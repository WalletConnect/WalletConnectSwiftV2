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

    public var responsePublisher: AnyPublisher<ResponseSubscriptionPayload, Never> {
        responsePublisherSubject.eraseToAnyPublisher()
    }
    public let responsePublisherSubject = PassthroughSubject<ResponseSubscriptionPayload, Never>()

    public let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()
    public var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
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
