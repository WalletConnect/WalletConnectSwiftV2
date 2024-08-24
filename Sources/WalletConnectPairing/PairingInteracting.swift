import Foundation

public protocol PairingInteracting {
    func pair(uri: WalletConnectURI) async throws

    func create(methods: [String]?)  async throws -> WalletConnectURI

    func getPairings() -> [Pairing]

    func getPairing(for topic: String) throws -> Pairing

    func disconnect(topic: String) async throws

#if DEBUG
    func cleanup() throws
#endif
}

public extension PairingInteracting {
    func create() async throws -> WalletConnectURI {
        return try await create(methods: nil)
    }
}
