import Foundation
import Combine

@testable import WalletConnectPairing

final class PairingClientMock: PairingClientProtocol {
    var pairCalled = false
    var disconnectPairingCalled = false
    
    func pair(uri: WalletConnectUtils.WalletConnectURI) async throws {
        pairCalled = true
    }
    
    func disconnect(topic: String) async throws {
        disconnectPairingCalled = true
    }
    
    func getPairings() -> [Pairing] {
        return [Pairing(topic: "", peer: nil, expiryDate: Date())]
    }
}
