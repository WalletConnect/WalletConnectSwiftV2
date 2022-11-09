
import Foundation

public class VerifyClient {


    public func verifyOrigin() async throws {

    }

    public func registerAttestation() async throws {

    }

    public func registerOriginProof() async throws {

    }
    
}

import DeviceCheck
import WalletConnectUtils

@available(iOS 14.0, *)
@available(macOS 11.0, *)
class AppAttestationRegistrer {
    enum Errors: Error {
        case attestationNotSupported
    }
    private let service: DCAppAttestService
    private let logger: ConsoleLogging

    init(logger: ConsoleLogging) throws {
        self.service = DCAppAttestService.shared
        self.logger = logger
        if !service.isSupported {
            throw Errors.attestationNotSupported
        }
        // TODO - check if attestation already performed
        generateKeys()
    }

    private func generateKeys() {
        service.generateKey { keyId, error in
            guard error == nil else {logger.debug }

            // Cache keyId for subsequent operations.
        }
    }
}
