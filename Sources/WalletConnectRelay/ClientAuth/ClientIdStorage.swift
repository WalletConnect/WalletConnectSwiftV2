import Foundation

public protocol ClientIdStoring {
    func getOrCreateKeyPair() throws -> SigningPrivateKey
    func getClientId() throws -> String
}

public struct ClientIdStorage: ClientIdStoring {
    private let key = "com.walletconnect.iridium.client_id"
    private let keychain: KeychainStorageProtocol
    private let clientIdMigrationController: ClientIdMigrationController?

    public init(
        keychain: KeychainStorageProtocol,
        clientIdMigrationController: ClientIdMigrationController? = nil
    ) {
        self.keychain = keychain
        self.clientIdMigrationController = clientIdMigrationController
        migrateClientIdIfNeeded()
    }

    public func getOrCreateKeyPair() throws -> SigningPrivateKey {
        do {
            return try keychain.read(key: key)
        } catch {
            let privateKey = SigningPrivateKey()
            try keychain.add(privateKey, forKey: key)
            return privateKey
        }
    }

    public func getClientId() throws -> String {
        let privateKey: SigningPrivateKey = try keychain.read(key: key)
        let pubKey = privateKey.publicKey.rawRepresentation
        return DIDKey(rawData: pubKey).did(variant: .ED25519)
    }

    private func migrateClientIdIfNeeded() {
        clientIdMigrationController?.migrateIfNeeded()
    }
}
