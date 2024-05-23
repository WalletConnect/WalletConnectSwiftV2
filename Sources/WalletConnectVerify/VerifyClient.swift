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
