@testable import WalletConnectVerify
import Foundation

class KeyAttestingMock: KeyAttesting {
    var keyAttested = false
    func attestKey(keyId: String, clientDataHash: Data) async throws {
        keyAttested = true
    }
}
