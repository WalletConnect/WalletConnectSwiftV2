import DeviceCheck
import Foundation

public protocol VerifyClientProtocol {
    func verifyOrigin(assertionId: String) async throws -> VerifyResponse
    func createVerifyContext(origin: String?, domain: String, isScam: Bool?) -> VerifyContext
    func createVerifyContextForLinkMode(redirectUniversalLink: String, domain: String) -> VerifyContext
}

public actor VerifyClient: VerifyClientProtocol {
    enum Errors: Error {
        case attestationNotSupported
    }
    
    let originVerifier: OriginVerifier
    let assertionRegistrer: AssertionRegistrer
    let appAttestationRegistrer: AppAttestationRegistrer
    let verifyContextFactory: VerifyContextFactory

    init(
        originVerifier: OriginVerifier,
        assertionRegistrer: AssertionRegistrer,
        appAttestationRegistrer: AppAttestationRegistrer,
        verifyContextFactory: VerifyContextFactory = VerifyContextFactory()
    ) {
        self.originVerifier = originVerifier
        self.assertionRegistrer = assertionRegistrer
        self.appAttestationRegistrer = appAttestationRegistrer
        self.verifyContextFactory = verifyContextFactory
    }

    public func registerAttestationIfNeeded() async throws {
        try await appAttestationRegistrer.registerAttestationIfNeeded()
    }

    public func verifyOrigin(assertionId: String) async throws -> VerifyResponse {
        return try await originVerifier.verifyOrigin(assertionId: assertionId)
    }

    public func verifyOrigin(attestationJWT: String, messageId: String) async throws -> VerifyResponse {

    }

    nonisolated public func createVerifyContext(origin: String?, domain: String, isScam: Bool?) -> VerifyContext {
        verifyContextFactory.createVerifyContext(origin: origin, domain: domain, isScam: isScam)
    }

    nonisolated public func createVerifyContextForLinkMode(redirectUniversalLink: String, domain: String) -> VerifyContext {
        verifyContextFactory.createVerifyContextForLinkMode(redirectUniversalLink: redirectUniversalLink, domain: domain)
    }

    public func registerAssertion() async throws {
        try await assertionRegistrer.registerAssertion()
    }
}

#if DEBUG

public struct VerifyClientMock: VerifyClientProtocol {
    
    public init() {}
    
    public func verifyOrigin(assertionId: String) async throws -> VerifyResponse {
        return VerifyResponse(origin: "domain.com", isScam: nil)
    }
    
    public func createVerifyContext(origin: String?, domain: String, isScam: Bool?) -> VerifyContext {
        return VerifyContext(origin: "domain.com", validation: .valid)
    }
    
    public func createVerifyContextForLinkMode(redirectUniversalLink: String, domain: String) -> VerifyContext {
        fatalError()
    }
}

#endif

class AttestationJWTVerifier {

    enum Errors: Error {
        case issuerDoesNotMatchVerifyServerPubKey
        case messageIdMismatch
        case invalidJWT
    }

    let verifyServerPubKeyManager: VerifyServerPubKeyManager

    init(verifyServerPubKeyManager: VerifyServerPubKeyManager) {
        self.verifyServerPubKeyManager = verifyServerPubKeyManager
    }

    // messageId - hash of the encrypted message supplied in the request
    func verify(attestationJWT: String, messageId: String) async throws {
        do {
            let verifyServerPubKey = try await verifyServerPubKeyManager.getPublicKey()
            try verifyJWTAgainstPubKey(attestationJWT, pubKey: verifyServerPubKey)
        } catch {
            let refreshedVerifyServerPubKey = try await verifyServerPubKeyManager.refreshKey()
            try verifyJWTAgainstPubKey(attestationJWT, pubKey: refreshedVerifyServerPubKey)
        }

        let claims = try decodeJWTClaims(jwtString: attestationJWT)
        guard messageId == claims.id else {
            throw Errors.messageIdMismatch
        }
    }

    func verifyJWTAgainstPubKey(_ jwtString: String, pubKey: String) throws {
        let signingPubKey = try SigningPublicKey(hex: pubKey)

        let validator = JWTValidator(jwtString: jwtString)
        guard try validator.isValid(publicKey: signingPubKey) else {
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

struct AttestationJWTClaims: Codable {

    var exp: UInt64

    var isScam: Bool?

    var id: String

    var origin: String
}

