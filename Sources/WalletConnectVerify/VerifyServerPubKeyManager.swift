import Foundation

class VerifyServerPubKeyManager {
    static let publicKeyStorageKey = "com.walletconnect.verify.pubKey"
    private let store: CodableStore<PublicKeyFetcher.VerifyServerPublicKey>
    private let fetcher: PublicKeyFetcher

    init(store: CodableStore<PublicKeyFetcher.VerifyServerPublicKey>, fetcher: PublicKeyFetcher) {
        self.store = store
        self.fetcher = fetcher
    }

    // Public async function to get the public key
    func getPublicKey() async throws -> String {
        if let localKey = try getPublicKeyFromLocalStorage(), !isKeyExpired(localKey) {
            return localKey.publicKey
        } else {
            let serverKey = try await fetcher.fetchPublicKey()
            savePublicKeyToLocalStorage(publicKey: serverKey)
            return serverKey.publicKey
        }
    }

    // Private function to get the public key from local storage
    private func getPublicKeyFromLocalStorage() throws -> PublicKeyFetcher.VerifyServerPublicKey? {
        return try store.get(key: Self.publicKeyStorageKey)
    }

    // Private function to check if the key is expired
    private func isKeyExpired(_ key: PublicKeyFetcher.VerifyServerPublicKey) -> Bool {
        let currentTime = Date().timeIntervalSince1970
        return currentTime >= key.expiresAt
    }

    // Private function to save the public key to local storage
    private func savePublicKeyToLocalStorage(publicKey: PublicKeyFetcher.VerifyServerPublicKey) {
        store.set(publicKey, forKey: Self.publicKeyStorageKey)
    }
}
