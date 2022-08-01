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

    init(relayClient: RelayClient,
         serializer: Serializing) {
        self.relayClient = relayClient
        self.serializer = serializer
    }

    func subscribe(topic: String) async throws {
        try await relayClient.subscribe(topic: topic)
    }

}
