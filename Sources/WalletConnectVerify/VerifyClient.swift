import DeviceCheck
import Foundation

public protocol VerifyClientProtocol {
    func verifyOrigin(assertionId: String) async throws -> VerifyResponse
    func createVerifyContext(origin: String?, domain: String, isScam: Bool?) -> VerifyContext
}

public actor VerifyClient: VerifyClientProtocol {
    enum Errors: Error {
        case attestationNotSupported
    }
    
    let originVerifier: OriginVerifier
    let assertionRegistrer: AssertionRegistrer
    let appAttestationRegistrer: AppAttestationRegistrer

    init(
        originVerifier: OriginVerifier,
        assertionRegistrer: AssertionRegistrer,
        appAttestationRegistrer: AppAttestationRegistrer
    ) {
        self.originVerifier = originVerifier
        self.assertionRegistrer = assertionRegistrer
        self.appAttestationRegistrer = appAttestationRegistrer
    }

    public func registerAttestationIfNeeded() async throws {
        try await appAttestationRegistrer.registerAttestationIfNeeded()
    }

    public func verifyOrigin(assertionId: String) async throws -> VerifyResponse {
        return try await originVerifier.verifyOrigin(assertionId: assertionId)
    }
    
    nonisolated public func createVerifyContext(origin: String?, domain: String, isScam: Bool?) -> VerifyContext {
        guard isScam == nil else {
            return VerifyContext(
                origin: origin,
                validation: .scam
            )
        }
        if let origin, let originUrl = URL(string: origin), let domainUrl = URL(string: domain) {
            return VerifyContext(
                origin: origin,
                validation: (originUrl.host == domainUrl.host) ? .valid : .invalid
            )
        } else {
            return VerifyContext(
                origin: origin,
                validation: .unknown
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
    
    public func verifyOrigin(assertionId: String) async throws -> VerifyResponse {
        return VerifyResponse(origin: "domain.com", isScam: nil)
    }
    
    public func createVerifyContext(origin: String?, domain: String, isScam: Bool?) -> VerifyContext {
        return VerifyContext(origin: "domain.com", validation: .valid)
    }
}

#endif
