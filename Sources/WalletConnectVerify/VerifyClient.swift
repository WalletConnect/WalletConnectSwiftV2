import DeviceCheck
import Foundation

public protocol VerifyClientProtocol {
    func verify(_ verificationType: VerificationType) async throws -> VerifyResponse
    func createVerifyContext(origin: String?, domain: String, isScam: Bool?, isVerified: Bool?) -> VerifyContext
    func createVerifyContextForLinkMode(redirectUniversalLink: String, domain: String) -> VerifyContext
}

public enum VerificationType {
    case v1(assertionId: String)
    case v2(attestationJWT: String, messageId: String)
}

public actor VerifyClient: VerifyClientProtocol {
    enum Errors: Error {
        case attestationNotSupported
    }
    
    let originVerifier: OriginVerifier
    let assertionRegistrer: AssertionRegistrer
    let appAttestationRegistrer: AppAttestationRegistrer
    let verifyContextFactory: VerifyContextFactory
    let attestationVerifier: AttestationJWTVerifier

    init(
        originVerifier: OriginVerifier,
        assertionRegistrer: AssertionRegistrer,
        appAttestationRegistrer: AppAttestationRegistrer,
        verifyContextFactory: VerifyContextFactory = VerifyContextFactory(),
        attestationVerifier: AttestationJWTVerifier
    ) {
        self.originVerifier = originVerifier
        self.assertionRegistrer = assertionRegistrer
        self.appAttestationRegistrer = appAttestationRegistrer
        self.verifyContextFactory = verifyContextFactory
        self.attestationVerifier = attestationVerifier
    }

    public func registerAttestationIfNeeded() async throws {
        try await appAttestationRegistrer.registerAttestationIfNeeded()
    }

    /// Verify V2 attestation JWT
    /// messageId - hash of the encrypted message supplied in the request
    /// assertionId - hash of decrytped message
    public func verify(_ verificationType: VerificationType) async throws -> VerifyResponse {
        switch verificationType {
        case .v1(let assertionId):
            return try await originVerifier.verifyOrigin(assertionId: assertionId)
        case .v2(let attestationJWT, let messageId):
            return try await attestationVerifier.verify(attestationJWT: attestationJWT, messageId: messageId)
        }
    }

    nonisolated public func createVerifyContext(origin: String?, domain: String, isScam: Bool?, isVerified: Bool?) -> VerifyContext {
        verifyContextFactory.createVerifyContext(origin: origin, domain: domain, isScam: isScam, isVerified: isVerified)
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

    public func verify(_ verificationType: VerificationType) async throws -> VerifyResponse {
        return VerifyResponse(origin: "domain.com", isScam: nil, isVerified: nil)
    }

    public func createVerifyContext(origin: String?, domain: String, isScam: Bool?, isVerified: Bool?) -> VerifyContext {
        return VerifyContext(origin: "domain.com", validation: .valid)
    }
    
    public func createVerifyContextForLinkMode(redirectUniversalLink: String, domain: String) -> VerifyContext {
        fatalError()
    }
}

#endif
