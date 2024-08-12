
import Foundation
import CryptoKit

struct AttestationJWTClaims: Codable {

    var exp: UInt64

    var isScam: Bool?

    var id: String

    var origin: String

    var isVerified: Bool
}

class AttestationJWTVerifier {

    enum Errors: Error {
        case issuerDoesNotMatchVerifyServerPubKey
        case messageIdMismatch
        case invalidJWT
    }

    let verifyServerPubKeyManager: VerifyServerPubKeyManagerProtocol

    init(verifyServerPubKeyManager: VerifyServerPubKeyManagerProtocol) {
        self.verifyServerPubKeyManager = verifyServerPubKeyManager
    }

    // messageId - hash of the encrypted message supplied in the request
    func verify(attestationJWT: String, messageId: String) async throws -> VerifyResponse {
        do {
            let verifyServerPubKey = try await verifyServerPubKeyManager.getPublicKey()
            try verifyJWTAgainstPubKey(attestationJWT, signingPubKey: verifyServerPubKey)
        } catch {
            let refreshedVerifyServerPubKey = try await verifyServerPubKeyManager.refreshKey()
            try verifyJWTAgainstPubKey(attestationJWT, signingPubKey: refreshedVerifyServerPubKey)
        }

        let claims = try decodeJWTClaims(jwtString: attestationJWT)
        guard messageId == claims.id else {
            throw Errors.messageIdMismatch
        }

        return VerifyResponse(origin: claims.origin, isScam: claims.isScam, isVerified: claims.isVerified)
    }

    func verifyJWTAgainstPubKey(_ jwtString: String, signingPubKey: P256.Signing.PublicKey) throws {
        let validator = P256JWTValidator(jwtString: jwtString)
        guard let isValid = try? validator.isValid(publicKey: signingPubKey),
                 isValid else {
            throw Errors.invalidJWT
        }
    }

    private func decodeJWTClaims(jwtString: String) throws -> AttestationJWTClaims {
        let components = jwtString.components(separatedBy: ".")

        guard components.count == 3 else { throw Errors.invalidJWT }

        let payload = components[1]
        guard let payloadData = Data(base64urlEncoded: payload) else {
            throw Errors.invalidJWT
        }

        let claims = try JSONDecoder().decode(AttestationJWTClaims.self, from: payloadData)
        return claims
    }
}

