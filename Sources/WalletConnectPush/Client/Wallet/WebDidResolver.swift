//     

import Foundation

class WebDidResolver {
    func resolveDidDoc(url: String) -> WebDidDoc {

    }
}

struct WebDidDoc {

}
// MARK: - WebDidDoc
struct WebDidDoc: Codable {
    let context: [String]
    let id: String
    let verificationMethod: [VerificationMethod]
    let authentication, assertionMethod, keyAgreement: [String]

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, verificationMethod, authentication, assertionMethod, keyAgreement
    }
}

// MARK: - VerificationMethod
struct VerificationMethod: Codable {
    let id, type, controller: String
    let publicKeyJwk: PublicKeyJwk
}

// MARK: - PublicKeyJwk
struct PublicKeyJwk: Codable {
    let kty, crv, x: String
    let y: String?
}
