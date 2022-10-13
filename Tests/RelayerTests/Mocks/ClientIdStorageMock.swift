import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

class ClientIdStorageMock: ClientIdStoring {

    var keyPair: SigningPrivateKey!

    func getOrCreateKeyPair() throws -> SigningPrivateKey {
        return keyPair
    }

    func getClientId() throws -> String {
        fatalError()
    }
}
