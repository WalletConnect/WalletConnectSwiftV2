import Foundation

final class NotifyWebDidResolver {

    private static var subscribeKey = "wc-notify-subscribe-key"
    private static var authenticationKey = "wc-notify-authentication-key"

    func resolveDidDoc(appDomain: String) async throws -> WebDidDoc {
        guard let didDocUrl = URL(string: "https://\(appDomain)/.well-known/did.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: didDocUrl)
        return try JSONDecoder().decode(WebDidDoc.self, from: data)
    }

    func resolveAgreementKey(didDoc: WebDidDoc) throws -> AgreementPublicKey {
        let keypath = "\(didDoc.id)#\(Self.subscribeKey)"
        let pubKeyBase64Url = try resolveKey(didDoc: didDoc, curve: .X25519, keyPath: keypath)
        return try AgreementPublicKey(base64url: pubKeyBase64Url)
    }

    func resolveAuthenticationKey(didDoc: WebDidDoc) throws -> Data {
        let keyPath = "\(didDoc.id)#\(Self.authenticationKey)"
        let pubKeyBase64Url = try resolveKey(didDoc: didDoc, curve: .Ed25519, keyPath: keyPath)
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

    func resolveKey(didDoc: WebDidDoc, curve: WebDidDoc.PublicKeyJwk.Curve, keyPath: String) throws -> String {
        guard let verificationMethod = didDoc.verificationMethod.first(where: { verificationMethod in verificationMethod.id == keyPath }) else { throw Errors.noVerificationMethodForKey }
        guard verificationMethod.publicKeyJwk.crv == curve else { throw Errors.unsupportedCurve }
        return verificationMethod.publicKeyJwk.x
    }
}
