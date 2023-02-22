import Foundation

protocol ClientIdStoring {
    func getOrCreateKeyPair() throws -> SigningPrivateKey
    func getClientId() throws -> String
}

struct ClientIdStorage: ClientIdStoring {
    private let key = "com.walletconnect.iridium.client_id"
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

    func getClientId() throws -> String {
        let privateKey: SigningPrivateKey = try keychain.read(key: key)
        let pubKey = privateKey.publicKey.rawRepresentation
        return DIDKey(rawData: pubKey).did(prefix: true, variant: .ED25519)
    }
}
