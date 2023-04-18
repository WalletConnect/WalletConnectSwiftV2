
import Foundation

// MARK: - WebDidDoc
struct WebDidDoc: Codable {
    let context: [String]
    let id: String
    let verificationMethod: [VerificationMethod]
    let authentication: [String]?
    let keyAgreement: [String]

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, verificationMethod, authentication, keyAgreement
    }
}
extension WebDidDoc {

    struct VerificationMethod: Codable {
        let id: String
        let type: String
        let controller: String
        let publicKeyJwk: PublicKeyJwk
    }

    struct PublicKeyJwk: Codable {
        enum Curve: String, Codable {
            case X25519 = "X25519"
        }
        let kty: String

        let crv: Curve
        /// The x member contains the x coordinate for the elliptic curve point. It is represented as the base64url encoding of the coordinate's big endian representation.
        let x: String
    }
}
