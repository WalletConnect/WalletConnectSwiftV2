import Foundation
import Combine

public protocol NetworkInteracting {
    var isSocketConnected: Bool { get }
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never> { get }
    var requestPublisher: AnyPublisher<(topic: String, request: RPCRequest, decryptedPayload: Data, publishedAt: Date, derivedTopic: String?, encryptedMessage: String, attestation: String?), Never> { get }
    func subscribe(topic: String) async throws
    func unsubscribe(topic: String)
    func batchSubscribe(topics: [String]) async throws
    func batchUnsubscribe(topics: [String]) async throws
    func request(_ request: RPCRequest, topic: String, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws
    func respond(topic: String, response: RPCResponse, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws
    func respondSuccess(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, envelopeType: Envelope.EnvelopeType) async throws
    func respondError(topic: String, requestId: RPCID, protocolMethod: ProtocolMethod, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws
    func handleHistoryRequest(topic: String, request: RPCRequest)
        
    func requestSubscription<Request: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<RequestSubscriptionPayload<Request>, Never>

    func responseSubscription<Request: Codable, Response: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<ResponseSubscriptionPayload<Request, Response>, Never>

    func responseErrorSubscription<Request: Codable>(
        on request: ProtocolMethod
    ) -> AnyPublisher<ResponseSubscriptionErrorPayload<Request>, Never>

    func subscribeOnRequest<RequestParams: Codable>(
        protocolMethod: ProtocolMethod,
        requestOfType: RequestParams.Type,
        errorHandler: ErrorHandler?,
        subscription: @escaping (RequestSubscriptionPayload<RequestParams>) async throws -> Void
    )

    func subscribeOnResponse<Request: Codable, Response: Codable>(
        protocolMethod: ProtocolMethod,
        requestOfType: Request.Type,
        responseOfType: Response.Type,
        errorHandler: ErrorHandler?,
        subscription: @escaping (ResponseSubscriptionPayload<Request, Response>) async throws -> Void
    )

    func awaitResponse<Request: Codable, Response: Codable>(
        request: RPCRequest,
        topic: String,
        method: ProtocolMethod,
        requestOfType: Request.Type,
        responseOfType: Response.Type,
        envelopeType: Envelope.EnvelopeType
    ) async throws -> Response

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
