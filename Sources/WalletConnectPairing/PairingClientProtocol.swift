public protocol PairingClientProtocol {
    func pair(uri: WalletConnectURI) async throws
}
