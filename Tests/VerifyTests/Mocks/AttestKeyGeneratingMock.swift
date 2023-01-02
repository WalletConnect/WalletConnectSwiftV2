import Foundation
@testable import WalletConnectVerify

class AttestKeyGeneratingMock: AttestKeyGenerating {
    var keysGenerated = false
    func generateKeys() async throws -> String {
        keysGenerated = true
        return ""
    }
}
