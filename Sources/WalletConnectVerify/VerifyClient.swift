import DeviceCheck
import Foundation

@available(iOS 14.0, *)
@available(macOS 11.0, *)
public actor VerifyClient {
    enum Errors: Error {
        case attestationNotSupported
    }
    let originVerifier: OriginVerifier
    let assertionRegistrer: AssertionRegistrer
    let appAttestationRegistrer: AppAttestationRegistrer

    init(originVerifier: OriginVerifier,
         assertionRegistrer: AssertionRegistrer,
         appAttestationRegistrer: AppAttestationRegistrer) throws {
        if !DCAppAttestService.shared.isSupported {
            throw Errors.attestationNotSupported
        }
        self.originVerifier = originVerifier
        self.assertionRegistrer = assertionRegistrer
        self.appAttestationRegistrer = appAttestationRegistrer
    }

    private  func registerAttestationIfNeeded() async throws {
        try await appAttestationRegistrer.registerAttestationIfNeeded()()
    }

    public func verifyOrigin() async throws {
        originVerifier.verifyOrigin()
    }


    public func registerAssertion() async throws {
        assertionRegistrer.registerAssertion()
    }
    
}
