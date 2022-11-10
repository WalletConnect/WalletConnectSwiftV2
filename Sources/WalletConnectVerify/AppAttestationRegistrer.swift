import Foundation
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

    let AttestKeyGenerator: AttestKeyGenerator
    let AttestChallengeProvider: AttestChallengeProvider
    let KeyAttestationService: KeyAttestationService

    init(logger: ConsoleLogging) throws {
        self.service = DCAppAttestService.shared
        self.logger = logger
        if !service.isSupported {
            throw Errors.attestationNotSupported
        }
        // TODO - check if attestation already performed
        generateKeys()
    }

    func registerAttestation() async throws {

    }

    private func generateKeys() {

    }

    private func getChallenge() {

    }

    private func attestKey() {

    }
}

protocol AttestKeyGenerating {
    func generateKeys() -> String
}

class AttestKeyGenerator: AttestKeyGenerating {
    func generateKeys() -> String {
//        service.generateKey { [unowned self] keyId, error in
//            guard error == nil else {
//                logger.debug(error!.localizedDescription)
//                return
//            }
//
//            // Cache keyId for subsequent operations.
//        }
        fatalError("not implemented")
    }


}
protocol AttestChallengeProviding {
    func getChallenge() async throws -> String
}

class AttestChallengeProvider: AttestChallengeProviding {
    func getChallenge() async throws -> String {
        fatalError("not implemented")
    }
}

protocol KeyAttesting {

    func attestKey(keyId: String, clientDataHash: String)
}

class KeyAttestationService: KeyAttesting {
    //    If the method, which accesses a remote Apple server, returns the serverUnavailable error, try attestation again later with the same key. For any other error, discard the key identifier and create a new key when you want to try again. Otherwise, send the completion handler’s attestation object and the keyId to your server for processing.
    func attestKey(keyId: String, clientDataHash: String) {
        fatalError("not implemented")

        service.attestKey(keyId, clientDataHash: hash) { attestation, error in
            guard error == nil else { /* Handle error and return. */ }

            // Send the attestation object to your server for verification.
        }
        let attestationString = attestation?.base64EncodedString()

    }


}
