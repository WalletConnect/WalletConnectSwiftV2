import Foundation
import CryptoKit

// PublicKeyFetcher class
protocol PublicKeyFetching {
    func fetchPublicKey() async throws -> VerifyServerPublicKey
}
struct VerifyServerPublicKey: Codable {
    enum Errors: Error {
        case invalisXCoordinateData
        case invalidYCoordinateData
    }
    let publicKey: JWK
    let expiresAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case publicKey = "publicKey"
        case expiresAt = "expiresAt"
    }

    struct JWK: Codable {
        let crv: String
        let ext: Bool
        let keyOps: [String]
        let kty: String
        let x: String
        let y: String

        enum CodingKeys: String, CodingKey {
            case crv
            case ext
            case keyOps = "key_ops"
            case kty
            case x
            case y
        }

        func P256SigningPublicKey() throws -> P256.Signing.PublicKey {
            let jwk = self
            // Convert the x and y values from base64url to Data
            guard let xData = Data(base64urlEncoded: jwk.x), xData.count == 32 else {
                print("Invalid x-coordinate data.")
                throw Errors.invalisXCoordinateData
            }
            guard let yData = Data(base64urlEncoded: jwk.y), yData.count == 32 else {
                print("Invalid y-coordinate data.")
                throw Errors.invalidYCoordinateData
            }

            // Concatenate the coordinates with the uncompressed point prefix 0x04
            let rawKeyData = xData + yData

            return try P256.Signing.PublicKey(rawRepresentation: rawKeyData)
        }
    }

}


class PublicKeyFetcher: PublicKeyFetching {
    enum Errors: Error, LocalizedError {
        case invalidURL
        case httpError(statusCode: Int, message: String)
        case decodingError(Error)
    }

    private let urlString = "https://verify.walletconnect.org/v2/public-key"


    func fetchPublicKey() async throws -> VerifyServerPublicKey {
        guard let url = URL(string: urlString) else {
            throw Errors.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Errors.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        do {
            let publicKeyResponse = try JSONDecoder().decode(VerifyServerPublicKey.self, from: data)
            return publicKeyResponse
        } catch {
            throw Errors.decodingError(error)
        }
    }
}

extension PublicKeyFetcher.Errors {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided is invalid."
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message)"
        case .decodingError:
            return "Failed to decode the JSON response."
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
