import Foundation
import WalletConnectRelay
import WalletConnectUtils
import Combine
import WalletConnectKMS
import JSONRPC

protocol NetworkInteracting {
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {get}
    func subscribe(topic: String) async throws
    func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws
    func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws
}

extension NetworkInteracting {
    func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType = .type0) async throws {
        try await self.request(request, topic: topic, tag: tag, envelopeType: envelopeType)
    }
}

class NetworkingInteractor: NetworkInteracting {
    private let relayClient: RelayClient
    private let serializer: Serializing
    private let rpcHistory: RPCHistory
    var requestPublisher: AnyPublisher<RequestSubscriptionPayload, Never> {
        requestPublisherSubject.eraseToAnyPublisher()
    }
    private let requestPublisherSubject = PassthroughSubject<RequestSubscriptionPayload, Never>()

    init(relayClient: RelayClient,
         serializer: Serializing,
         rpcHistory: RPCHistory) {
        self.relayClient = relayClient
        self.serializer = serializer
        self.rpcHistory = rpcHistory
    }

    func subscribe(topic: String) async throws {
        try await relayClient.subscribe(topic: topic)
    }

    func request(_ request: RPCRequest, topic: String, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.set(request, forTopic: topic, emmitedBy: .local)
        let message = try! serializer.serialize(topic: topic, encodable: request, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: tag)
    }

    func respond(topic: String, response: RPCResponse, tag: Int, envelopeType: Envelope.EnvelopeType) async throws {
        try rpcHistory.resolve(response)
        let message = try! serializer.serialize(topic: topic, encodable: response, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: tag)
    }
}
