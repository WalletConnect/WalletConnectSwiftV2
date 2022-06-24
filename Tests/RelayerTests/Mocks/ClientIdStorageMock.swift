import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

class ClientIdStorageMock: ClientIdStoring {
    var keyPair: SigningPrivateKey!

    func getOrCreateKeyPair() async throws -> SigningPrivateKey {
        return keyPair
    }
}
