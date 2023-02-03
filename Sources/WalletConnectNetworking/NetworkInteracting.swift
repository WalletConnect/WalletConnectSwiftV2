import Foundation
import Combine

public protocol NetworkInteracting {
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest), Never> { get }
    func subscribe(topic: String) async throws
    func unsubscribe(topic: String)
    func batchSubscribe(topics: [String]) async throws
    func batchUnsubscribe(topics: [String]) async throws
    func request(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws
    func requestNetworkAck(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod) async throws
    func respond(topic: String, response: RPCResponse, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws
    func respondSuccess(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws
    func respondError(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws

    func requestSubscription<Request: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<RequestSubscriptionPayload<Request>, Never>

    func responseSubscription<Request: Codable, Response: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<ResponseSubscriptionPayload<Request, Response>, Never>

    func responseErrorSubscription<Request: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never>

    func getClientId() throws -> String
}

extension NetworkInteracting {
    public func request(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod) async throws {
        try await self.request(request, topic: topic, protocolMethod: protocolMethod, envelopeType: .type0)
    }

    public func respond(topic: String, response: RPCResponse, protocolMethod: ProtocolMethod) async throws {
        try await self.respond(topic: topic, response: response, protocolMethod: protocolMethod, envelopeType: .type0)
    }

    public func respondSuccess(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod) async throws {
        try await self.respondSuccess(topic: topic, requestId: requestId, protocolMethod: protocolMethod, envelopeType: .type0)
    }

    public func respondError(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, reason: Reason) async throws {
        try await self.respondError(topic: topic, requestId: requestId, protocolMethod: protocolMethod, reason: reason, envelopeType: .type0)
    }
}
