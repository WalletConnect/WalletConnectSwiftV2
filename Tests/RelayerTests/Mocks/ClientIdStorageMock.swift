import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

class ClientIdStorageMock: ClientIdStoring {
    var keyPair: AgreementPrivateKey!

    func getOrCreateKeyPair() async throws -> AgreementPrivateKey {
        return keyPair
    }
}
