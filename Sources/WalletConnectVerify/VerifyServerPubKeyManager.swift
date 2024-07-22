import Foundation

class VerifyServerPubKeyManager {
    static let publicKeyStorageKey = "verify_server_pub_key"
    private let store: CodableStore<PublicKeyFetcher.VerifyServerPublicKey>
    private let fetcher: PublicKeyFetching

    init(store: CodableStore<PublicKeyFetcher.VerifyServerPublicKey>, fetcher: PublicKeyFetching = PublicKeyFetcher()) {
        self.store = store
        self.fetcher = fetcher

        // Check if there is a cached, non-expired key on initialization
        Task {
            do {
                if let localKey = try getPublicKeyFromLocalStorage(), !isKeyExpired(localKey) {
                    // Key is valid, no action needed
                } else {
                    // No valid key, fetch and store a new one
                    let serverKey = try await fetcher.fetchPublicKey()
                    savePublicKeyToLocalStorage(publicKey: serverKey)
                }
            } catch {
                print("Failed to initialize public key: \(error)")
            }
        }
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
