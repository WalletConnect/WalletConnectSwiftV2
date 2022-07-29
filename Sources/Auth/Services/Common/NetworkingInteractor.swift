import Foundation
import WalletConnectRelay

protocol NetworkInteracting {
    func subscribe(topic: String) async throws
}

class NetworkingInteractor: NetworkInteracting {
    private let relayClient: RelayClient

    init(relayClient: RelayClient) {
        self.relayClient = relayClient
    }

    func subscribe(topic: String) async throws {
        try await relayClient.subscribe(topic: topic)
    }
}
