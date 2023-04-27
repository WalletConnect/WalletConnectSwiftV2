import DeviceCheck
import Foundation
import WalletConnectUtils
import WalletConnectNetworking

public actor VerifyClient {
    enum Errors: Error {
        case attestationNotSupported
    }
    
    public let verifyHost: String
    let originVerifier: OriginVerifier
    let assertionRegistrer: AssertionRegistrer
    let appAttestationRegistrer: AppAttestationRegistrer

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

    public func verifyOrigin() async throws {
        try await originVerifier.verifyOrigin()
    }

    public func registerAssertion(attestationId: String) async throws -> String {
        return try await assertionRegistrer.registerAssertion(attestationId: attestationId)
    }
}
