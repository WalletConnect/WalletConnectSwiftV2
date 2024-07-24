import Foundation

// PublicKeyFetcher class
protocol PublicKeyFetching {
    func fetchPublicKey() async throws -> VerifyServerPublicKey
}
struct VerifyServerPublicKey: Codable {
    let publicKey: String
    let expiresAt: TimeInterval
}
class PublicKeyFetcher: PublicKeyFetching {

    private let urlString = "https://verify.walletconnect.org/v2/public-key"

    func fetchPublicKey() async throws -> VerifyServerPublicKey {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        do {
            let publicKeyResponse = try JSONDecoder().decode(VerifyServerPublicKey.self, from: data)
            return publicKeyResponse
        } catch {
            print("Decoding error: \(error)")
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSON"])
        }
    }
}

#if DEBUG
class MockPublicKeyFetcher: PublicKeyFetching {
    var publicKey: VerifyServerPublicKey?
    var error: Error?

    func fetchPublicKey() async throws -> VerifyServerPublicKey {
        if let error = error {
            throw error
        }
        return publicKey!
    }
}
#endif
