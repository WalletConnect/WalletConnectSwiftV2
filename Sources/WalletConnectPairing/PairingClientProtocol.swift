public protocol PairingClientProtocol {
    func pair(uri: WalletConnectURI) async throws
    func register(supportedMethods: [String]) 
    func disconnect(topic: String) async throws
    func getPairings() -> [Pairing]
}
