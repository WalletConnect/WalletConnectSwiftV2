import Foundation

final class NotifyWebDidResolver {

    private static var subscribeKey = "wc-notify-subscribe-key"
    private static var authenticationKey = "wc-notify-authentication-key"

    func resolveAgreementKey(domain: String) async throws -> AgreementPublicKey {
        let didDoc = try await resolveDidDoc(domainUrl: domain)
        let subscribeKeyPath = "\(didDoc.id)#\(Self.subscribeKey)"
        guard let verificationMethod = didDoc.verificationMethod.first(where: { verificationMethod in verificationMethod.id == subscribeKeyPath }) else { throw Errors.noVerificationMethodForKey }
        guard verificationMethod.publicKeyJwk.crv == .X25519 else { throw Errors.unsupportedCurve}
        let pubKeyBase64Url = verificationMethod.publicKeyJwk.x
        return try AgreementPublicKey(base64url: pubKeyBase64Url)
    }

    // TODO - Add cache for diddocs

    func resolveAuthenticationKey(domain: String) async throws -> Data {
        let didDoc = try await resolveDidDoc(domainUrl: domain)
        let authenticationKeyPath = "\(didDoc.id)#\(Self.authenticationKey)"
        guard let verificationMethod = didDoc.verificationMethod.first(where: { verificationMethod in verificationMethod.id == authenticationKeyPath }) else { throw Errors.noVerificationMethodForKey }
        guard verificationMethod.publicKeyJwk.crv == .Ed25519 else { throw Errors.unsupportedCurve}
        let pubKeyBase64Url = verificationMethod.publicKeyJwk.x
        guard let raw = Data(base64url: pubKeyBase64Url) else { throw Errors.invalidBase64urlString }
        return raw
    }
}

private extension NotifyWebDidResolver {

    enum Errors: Error {
        case invalidUrl
        case invalidBase64urlString
        case noVerificationMethodForKey
        case unsupportedCurve
    }

    func resolveDidDoc(domainUrl: String) async throws -> WebDidDoc {
        guard let didDocUrl = URL(string: "https://\(domainUrl)/.well-known/did.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: didDocUrl)
        return try JSONDecoder().decode(WebDidDoc.self, from: data)
    }
}
