import Foundation
import WalletConnectKMS

protocol ClientIdStoring {
    func getOrCreateKeyPair() async throws -> AgreementPrivateKey
}

actor ClientIdStorage: ClientIdStoring {
    func getOrCreateKeyPair() async throws -> AgreementPrivateKey {
        fatalError("not implemented")
    }


}
