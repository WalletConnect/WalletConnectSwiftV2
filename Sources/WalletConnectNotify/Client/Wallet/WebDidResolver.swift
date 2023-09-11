import Foundation

final class WebDidResolver {

    func resolveAgreementKey(domain: String) async throws -> AgreementPublicKey {
        let didDoc = try await resolveDidDoc(domainUrl: domain)
        guard let keyAgreement = didDoc.keyAgreement.first else { throw Errors.didDocDoesNotContainKeyAgreement }
        guard let verificationMethod = didDoc.verificationMethod.first(where: { verificationMethod in verificationMethod.id == keyAgreement }) else { throw Errors.noVerificationMethodForKey }
        guard verificationMethod.publicKeyJwk.crv == .X25519 else { throw Errors.unsupportedCurve}
        let pubKeyBase64Url = verificationMethod.publicKeyJwk.x
        return try AgreementPublicKey(base64url: pubKeyBase64Url)
    }

    // TODO - Add cache for diddocs

    func resolveAuthenticationKey(domain: String) async throws -> Data {
        let didDoc = try await resolveDidDoc(domainUrl: domain)
        guard let authentication = didDoc.authentication?.first else { throw Errors.didDocDoesNotContainAuthenticationKey }
        guard let verificationMethod = didDoc.verificationMethod.first(where: { verificationMethod in verificationMethod.id == authentication }) else { throw Errors.noVerificationMethodForKey }
        guard verificationMethod.publicKeyJwk.crv == .Ed25519 else { throw Errors.unsupportedCurve}
        let pubKeyBase64Url = verificationMethod.publicKeyJwk.x
        guard let raw = Data(base64url: pubKeyBase64Url) else { throw Errors.invalidBase64urlString }
        return raw
    }
}

private extension WebDidResolver {

    enum Errors: Error {
        case invalidUrl
        case invalidBase64urlString
        case didDocDoesNotContainKeyAgreement
        case didDocDoesNotContainAuthenticationKey
        case noVerificationMethodForKey
        case unsupportedCurve
    }

    func resolveDidDoc(domainUrl: String) async throws -> WebDidDoc {
        guard let didDocUrl = URL(string: "https://\(domainUrl)/.well-known/did.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: didDocUrl)
        return try JSONDecoder().decode(WebDidDoc.self, from: data)
    }
}
