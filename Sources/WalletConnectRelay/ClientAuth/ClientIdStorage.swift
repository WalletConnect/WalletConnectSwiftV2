import Foundation
import WalletConnectKMS

protocol ClientIdStoring {
    func getOrCreateKeyPair() throws -> SigningPrivateKey
}

struct ClientIdStorage: ClientIdStoring {
    private let key = "com.walletconnect.irn.client_id"
    private let keychain: KeychainStorageProtocol

    init(keychain: KeychainStorageProtocol) {
        self.keychain = keychain
    }

    func getOrCreateKeyPair() throws -> SigningPrivateKey {
        do {
            return try keychain.read(key: key)
        } catch {
            let privateKey = SigningPrivateKey()
            try keychain.add(privateKey, forKey: key)
            return privateKey
        }
    }
}
