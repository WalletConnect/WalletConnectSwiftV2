import Foundation

class VerifyServerPubKeyManager {
    static let publicKeyStorageKey = "com.walletconnect.verify.pubKey"
    private let store: CodableStore<PublicKeyFetcher.VerifyServerPublicKey>
    private let fetcher: PublicKeyFetcher

    init(store: CodableStore<PublicKeyFetcher.VerifyServerPublicKey>, fetcher: PublicKeyFetcher) {
        self.store = store
        self.fetcher = fetcher
    }

    func getPublicKey() async throws -> String {
        if let localKey = try getPublicKeyFromLocalStorage(), !isKeyExpired(localKey) {
            return localKey.publicKey
        } else {
            let serverKey = try await fetcher.fetchPublicKey()
            savePublicKeyToLocalStorage(publicKey: serverKey)
            return serverKey.publicKey
        }
    }

    func refreshKey() async throws -> String {
        let serverKey = try await fetcher.fetchPublicKey()
        savePublicKeyToLocalStorage(publicKey: serverKey)
        return serverKey.publicKey
    }

    private func getPublicKeyFromLocalStorage() throws -> PublicKeyFetcher.VerifyServerPublicKey? {
        return try store.get(key: Self.publicKeyStorageKey)
    }

    private func isKeyExpired(_ key: PublicKeyFetcher.VerifyServerPublicKey) -> Bool {
        let currentTime = Date().timeIntervalSince1970
        return currentTime >= key.expiresAt
    }

    private func savePublicKeyToLocalStorage(publicKey: PublicKeyFetcher.VerifyServerPublicKey) {
        store.set(publicKey, forKey: Self.publicKeyStorageKey)
    }
}
