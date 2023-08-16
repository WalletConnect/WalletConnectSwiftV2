import DeviceCheck
import Foundation

public protocol VerifyClientProtocol {
    func verifyOrigin(assertionId: String) async throws -> String
    func createVerifyContext(origin: String?, domain: String) -> VerifyContext
}

public actor VerifyClient: VerifyClientProtocol {
    enum Errors: Error {
        case attestationNotSupported
    }
    
    let originVerifier: OriginVerifier
    let assertionRegistrer: AssertionRegistrer
    let appAttestationRegistrer: AppAttestationRegistrer
    
    private let verifyHost: String

    init(
        verifyHost: String,
        originVerifier: OriginVerifier,
        assertionRegistrer: AssertionRegistrer,
        appAttestationRegistrer: AppAttestationRegistrer
    ) {
        self.verifyHost = verifyHost
        self.originVerifier = originVerifier
        self.assertionRegistrer = assertionRegistrer
        self.appAttestationRegistrer = appAttestationRegistrer
    }

    public func registerAttestationIfNeeded() async throws {
        try await appAttestationRegistrer.registerAttestationIfNeeded()
    }

    public func verifyOrigin(assertionId: String) async throws -> String {
        return try await originVerifier.verifyOrigin(assertionId: assertionId)
    }
    
    nonisolated public func createVerifyContext(origin: String?, domain: String) -> VerifyContext {
        if let origin, let originUrl = URL(string: origin), let domainUrl = URL(string: domain) {
            return VerifyContext(
                origin: origin,
                validation: (originUrl.host == domainUrl.host) ? .valid : .invalid,
                verifyUrl: verifyHost
            )
        } else {
            return VerifyContext(
                origin: origin,
                validation: .unknown,
                verifyUrl: verifyHost
            )
        }
    }

    public func registerAssertion() async throws {
        try await assertionRegistrer.registerAssertion()
    }
}

#if DEBUG

public struct VerifyClientMock: VerifyClientProtocol {
    public init() {}
    
    public func verifyOrigin(assertionId: String) async throws -> String {
        return "domain.com"
    }
    
    public func createVerifyContext(origin: String?, domain: String) -> VerifyContext {
        return VerifyContext(origin: "domain.com", validation: .valid, verifyUrl: "verify.walletconnect.com")
    }
}

#endif
