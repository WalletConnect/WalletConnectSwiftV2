import Foundation
import Combine
import JSONRPC
import WalletConnectKMS
import WalletConnectRelay

public protocol NetworkInteracting {
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    func subscribe(topic: String) async throws
    func unsubscribe(topic: String)
    func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws
    func requestNetworkAck(_ request: RPCRequest, topic: String, tag: Int) async throws
    func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws
    func respondSuccess(topic: String, requestId: RPCID, tag: Int, envelopeType: Envelope.EnvelopeType) async throws
    func respondError(topic: String, requestId: RPCID, tag: Int, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws

    func requestSubscription<Request: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<RequestSubscriptionPayload<Request>, Never>

    func requestSubscription(on requests: [ProtocolMethod]) -> AnyPublisher<(topic: String, request: RPCRequest), Never> 

    func responseSubscription<Request: Codable, Response: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<ResponseSubscriptionPayload<Request, Response>, Never>

    func responseErrorSubscription<Request: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never>
}

extension NetworkInteracting {
    public func request(_ request: RPCRequest, topic: String, tag: Int) async throws {
        try await self.request(request, topic: topic, tag: tag, envelopeType: .type0)
    }

    public func respond(topic: String, response: RPCResponse, tag: Int) async throws {
        try await self.respond(topic: topic, response: response, tag: tag, envelopeType: .type0)
    }

    public func respondSuccess(topic: String, requestId: RPCID, tag: Int) async throws {
        try await self.respondSuccess(topic: topic, requestId: requestId, tag: tag, envelopeType: .type0)
    }

    public func respondError(topic: String, requestId: RPCID, tag: Int, reason: Reason) async throws {
        try await self.respondError(topic: topic, requestId: requestId, tag: tag, reason: reason, envelopeType: .type0)
    }
}
