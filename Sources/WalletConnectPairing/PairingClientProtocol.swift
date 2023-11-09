import Combine

public protocol PairingClientProtocol {
    var deleteResponsePublisher: AnyPublisher<String, Never> { get }
    func pair(uri: WalletConnectURI) async throws
    func disconnect(topic: String) async throws
    func getPairings() -> [Pairing]
}
