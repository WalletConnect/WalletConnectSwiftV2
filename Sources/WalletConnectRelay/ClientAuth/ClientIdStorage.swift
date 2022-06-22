import Foundation
import WalletConnectKMS

protocol ClientIdStoring {
    func getOrCreateKeyPair() async throws -> SigningPrivateKey
}

actor ClientIdStorage: ClientIdStoring {
    func getOrCreateKeyPair() async throws -> SigningPrivateKey {
        fatalError("not implemented")
    }

}
