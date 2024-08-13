import Foundation
import CryptoKit

protocol VerifyServerPubKeyManagerProtocol {
    func getPublicKey() async throws -> P256.Signing.PublicKey
    func refreshKey() async throws -> P256.Signing.PublicKey
}

class VerifyServerPubKeyManager: VerifyServerPubKeyManagerProtocol {

    static let publicKeyStorageKey = "verify_server_pub_key"
    private let store: CodableStore<VerifyServerPublicKey>
    private let fetcher: PublicKeyFetching

    init(store: CodableStore<VerifyServerPublicKey>, fetcher: PublicKeyFetching = PublicKeyFetcher()) {
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

    func getPublicKey() async throws -> P256.Signing.PublicKey {
        if let localKey = try getPublicKeyFromLocalStorage(), !isKeyExpired(localKey) {
            return try localKey.publicKey.P256SigningPublicKey()
        } else {
            let serverKey = try await fetcher.fetchPublicKey()
            savePublicKeyToLocalStorage(publicKey: serverKey)
            return try serverKey.publicKey.P256SigningPublicKey()
        }
    }

    func refreshKey() async throws -> P256.Signing.PublicKey {
        let serverKey = try await fetcher.fetchPublicKey()
        savePublicKeyToLocalStorage(publicKey: serverKey)
        return try serverKey.publicKey.P256SigningPublicKey()
    }

    private func getPublicKeyFromLocalStorage() throws -> VerifyServerPublicKey? {
        return try store.get(key: Self.publicKeyStorageKey)
    }

    private func isKeyExpired(_ key: VerifyServerPublicKey) -> Bool {
        let currentTime = Date().timeIntervalSince1970
        return currentTime >= key.expiresAt
    }

    private func savePublicKeyToLocalStorage(publicKey: VerifyServerPublicKey) {
        store.set(publicKey, forKey: Self.publicKeyStorageKey)
    }
}

#if DEBUG
class VerifyServerPubKeyManagerMock: VerifyServerPubKeyManagerProtocol {
    var mockPublicKey: P256.Signing.PublicKey?
    var error: Error?

    init() {
        let jwk = VerifyServerPublicKey.JWK(
            crv: "P-256",
            ext: true,
            keyOps: ["verify"],
            kty: "EC",
            x: "CbL4DOYOb1ntd-8OmExO-oS0DWCMC00DntrymJoB8tk",
            y: "KTFwjHtQxGTDR91VsOypcdBfvbo6sAMj5p4Wb-9hRA0"
        )
        mockPublicKey = try? jwk.P256SigningPublicKey()
    }

    func getPublicKey() async throws -> P256.Signing.PublicKey {
        if let error = error {
            throw error
        }
        return mockPublicKey!
    }

    func refreshKey() async throws -> P256.Signing.PublicKey {
        if let error = error {
            throw error
        }
        return mockPublicKey!
    }
}
#endif
