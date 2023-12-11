import Combine

public protocol PairingClientProtocol {
    var logsPublisher: AnyPublisher<Log, Never> {get}
    var pairingDeletePublisher: AnyPublisher<(code: Int, message: String), Never> {get}
    func pair(uri: WalletConnectURI) async throws
    func register(supportedMethods: [String]) async
    func disconnect(topic: String) async throws
    func getPairings() -> [Pairing]
}
