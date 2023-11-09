import Foundation
import Combine

public protocol PairingInteracting {
    var deleteResponsePublisher: AnyPublisher<String, Never> { get }
        
    func pair(uri: WalletConnectURI) async throws

    func create()  async throws -> WalletConnectURI

    func getPairings() -> [Pairing]

    func getPairing(for topic: String) throws -> Pairing

    func ping(topic: String) async throws

    func disconnect(topic: String) async throws

#if DEBUG
    func cleanup() throws
#endif
}
