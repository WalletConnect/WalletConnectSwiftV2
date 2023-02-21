public protocol PairingClientProtocol {
    func pair(uri: WalletConnectURI) async throws
    func disconnect(topic: String) async throws
    func getPairings() -> [Pairing]
}
