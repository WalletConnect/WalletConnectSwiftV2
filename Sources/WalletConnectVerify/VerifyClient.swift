
import Foundation

@available(iOS 14.0, *)
@available(macOS 11.0, *)
public actor VerifyClient {

    let originVerifier: OriginVerifier
    let assertionRegistrer: AssertionRegistrer
    let appAttestationRegistrer: AppAttestationRegistrer

    init(originVerifier: OriginVerifier,
         assertionRegistrer: AssertionRegistrer,
         appAttestationRegistrer: AppAttestationRegistrer) {
        self.originVerifier = originVerifier
        self.assertionRegistrer = assertionRegistrer
        self.appAttestationRegistrer = appAttestationRegistrer
    }

    public func verifyOrigin() async throws {

    }

    public func registerAttestation() async throws {

    }

    public func registerAssertion() async throws {

    }
    
}
