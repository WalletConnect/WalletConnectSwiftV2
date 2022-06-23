import Foundation
import WalletConnectKMS

protocol ClientIdStoring {
    func getOrCreateKeyPair() async throws -> WalletConnectKMS.SigningPrivateKey
}

actor ClientIdStorage: ClientIdStoring {
    func getOrCreateKeyPair() async throws -> WalletConnectKMS.SigningPrivateKey {
        fatalError("not implemented")
    }

}
