import Foundation

final class WebDidResolver {

    func resolvePublicKey(dappUrl: String) async throws -> AgreementPublicKey {
        let didDoc = try await resolveDidDoc(domainUrl: dappUrl)
        guard let keyAgreement = didDoc.keyAgreement.first else { throw Errors.didDocDoesNotContainKeyAgreement }
        guard let verificationMethod = didDoc.verificationMethod.first(where: { verificationMethod in verificationMethod.id == keyAgreement }) else { throw Errors.noVerificationMethodForKey }
        guard verificationMethod.publicKeyJwk.crv == .X25519 else { throw Errors.unsupportedCurve}
        let pubKeyBase64Url = verificationMethod.publicKeyJwk.x
        return try AgreementPublicKey(base64url: pubKeyBase64Url)
    }
}

private extension WebDidResolver {

    enum Errors: Error {
        case invalidUrl
        case didDocDoesNotContainKeyAgreement
        case noVerificationMethodForKey
        case unsupportedCurve
    }

    func resolveDidDoc(domainUrl: String) async throws -> WebDidDoc {
        guard let didDocUrl = URL(string: "\(domainUrl)/.well-known/did.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: didDocUrl)
        return try JSONDecoder().decode(WebDidDoc.self, from: data)
    }
}
