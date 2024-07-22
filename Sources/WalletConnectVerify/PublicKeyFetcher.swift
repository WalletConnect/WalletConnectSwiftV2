import Foundation

// PublicKeyFetcher class
protocol PublicKeyFetching {
    func fetchPublicKey() async throws -> PublicKeyFetcher.VerifyServerPublicKey
}
class PublicKeyFetcher: PublicKeyFetching {
    struct VerifyServerPublicKey: Codable {
        let publicKey: String
        let expiresAt: TimeInterval
    }

    private let urlString = "https://verify.walletconnect.org/v2/public-key"

    func fetchPublicKey() async throws -> VerifyServerPublicKey {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let publicKeyResponse = try JSONDecoder().decode(VerifyServerPublicKey.self, from: data)
        return publicKeyResponse
    }
}

#if DEBUG
class MockPublicKeyFetcher: PublicKeyFetching {
    var publicKey: PublicKeyFetcher.VerifyServerPublicKey?
    var error: Error?

    func fetchPublicKey() async throws -> PublicKeyFetcher.VerifyServerPublicKey {
        if let error = error {
            throw error
        }
        return publicKey!
    }
}
#endif
