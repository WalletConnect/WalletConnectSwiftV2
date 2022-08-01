import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS

protocol NetworkInteracting {
    func subscribe(topic: String) async throws
    func request(_ request: JSONRPCRequest<AuthRequestParams>, topic: String, envelopeType: Envelope.EnvelopeType) async throws
}

extension NetworkInteracting {
    func request(_ request: JSONRPCRequest<AuthRequestParams>, topic: String, envelopeType: Envelope.EnvelopeType = .type0) async throws {
        try await self.request(request, topic: topic, envelopeType: envelopeType)
    }
}


class NetworkingInteractor: NetworkInteracting {
    private let relayClient: RelayClient
    private let serializer: Serializing
    private let jsonRpcHistory: JsonRpcHistory<AuthRequestParams>

    init(relayClient: RelayClient,
         serializer: Serializing,
         jsonRpcHistory: JsonRpcHistory<AuthRequestParams>) {
        self.relayClient = relayClient
        self.serializer = serializer
        self.jsonRpcHistory = jsonRpcHistory
    }

    func subscribe(topic: String) async throws {
        try await relayClient.subscribe(topic: topic)
    }

    func request(_ request: JSONRPCRequest<AuthRequestParams>, topic: String, envelopeType: Envelope.EnvelopeType) async throws {
        try jsonRpcHistory.set(topic: topic, request: request)
        let message = try! serializer.serialize(topic: topic, encodable: request, envelopeType: envelopeType)
        try await relayClient.publish(topic: topic, payload: message, tag: AuthRequestParams.tag)
    }
}
