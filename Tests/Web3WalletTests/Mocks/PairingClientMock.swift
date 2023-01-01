import Foundation
import Combine

@testable import WalletConnectPairing

final class PairingClientMock: PairingClientProtocol {
    var pairCalled = false
    
    func pair(uri: WalletConnectUtils.WalletConnectURI) async throws {
        pairCalled = true
    }
}
