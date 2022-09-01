import Foundation
import Combine
import JSONRPC
import WalletConnectKMS

public protocol NetworkInteracting {
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {get}
    var responsePublisher: AnyPublisher<ResponseSubscriptionPayload, Never> {get}
    func subscribe(topic: String) async throws
    func unsubscribe(topic: String)
    func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws
    func requestNetworkAck(_ request: RPCRequest, topic: String, tag: Int) async throws
    func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws
    func respondError(topic: String, requestId: RPCID, tag: Int, reason: Reason, envelopeType: Envelope.EnvelopeType) async throws
}

extension NetworkInteracting {
    public func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType = .type0) async throws {
        try await self.request(request, topic: topic, tag: tag, envelopeType: envelopeType)
    }
}
