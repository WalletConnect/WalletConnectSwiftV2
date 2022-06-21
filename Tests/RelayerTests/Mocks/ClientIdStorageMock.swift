import WalletConnectKMS
@testable import WalletConnectRelay
import Foundation

actor ClientIdStorageMock: ClientIdStoring {
    var keyPair: AgreementPrivateKey!

    func getOrCreateKeyPair() async throws -> AgreementPrivateKey {
        return keyPair
    }
}
