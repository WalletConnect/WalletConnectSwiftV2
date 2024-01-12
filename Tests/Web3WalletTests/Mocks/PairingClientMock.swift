import Foundation
import Combine

@testable import WalletConnectPairing

final class PairingClientMock: PairingClientProtocol {
    var pairingStatePublisher: AnyPublisher<Bool, Never> {
        pairingStatePublisherSubject.eraseToAnyPublisher()
    }
    var pairingStatePublisherSubject = PassthroughSubject<Bool, Never>()

    var pairingExpirationPublisher: AnyPublisher<WalletConnectPairing.Pairing, Never> {
        return pairingExpirationPublisherSubject.eraseToAnyPublisher()
    }
    var pairingExpirationPublisherSubject = PassthroughSubject<WalletConnectPairing.Pairing, Never>()


    var pairingDeletePublisher: AnyPublisher<(code: Int, message: String), Never> {
        pairingDeletePublisherSubject.eraseToAnyPublisher()
    }

    var pairingDeletePublisherSubject = PassthroughSubject<(code: Int, message: String), Never>()


    var logsSubject = PassthroughSubject<WalletConnectUtils.Log, Never>()

    var logsPublisher: AnyPublisher<WalletConnectUtils.Log, Never> {
        return logsSubject.eraseToAnyPublisher()
    }

    var pairCalled = false
    var disconnectPairingCalled = false
    
    func pair(uri: WalletConnectUtils.WalletConnectURI) async throws {
        pairCalled = true
    }
    
    func disconnect(topic: String) async throws {
        disconnectPairingCalled = true
    }
    
    func getPairings() -> [Pairing] {
        return [Pairing(WCPairing.stub())]
    }
}
