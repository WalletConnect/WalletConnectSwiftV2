import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

class ClientIdStorageMock: ClientIdStoring {
    func getClientId() throws -> String {
        fatalError()
    }

    var keyPair: SigningPrivateKey!

    func getOrCreateKeyPair() throws -> SigningPrivateKey {
        return keyPair
    }
}
