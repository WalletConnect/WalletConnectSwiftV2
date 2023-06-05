import DeviceCheck
import Foundation

public actor VerifyClient {
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
    ) throws {
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
    
    public func createVerifyContext(origin: String?, domain: String) -> VerifyContext {
        return VerifyContext(
            origin: origin,
            validation: (origin == domain) ? .valid : (origin == nil ? .unknown : .invalid),
            verifyUrl: verifyHost
        )
    }

    public func registerAssertion() async throws {
        try await assertionRegistrer.registerAssertion()
    }
}
