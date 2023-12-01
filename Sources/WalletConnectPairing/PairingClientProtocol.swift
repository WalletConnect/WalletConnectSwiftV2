import Combine

public protocol PairingClientProtocol {
    var logsPublisher: AnyPublisher<Log, Never> {get}
    func pair(uri: WalletConnectURI) async throws
    func disconnect(topic: String) async throws
    func getPairings() -> [Pairing]
}
