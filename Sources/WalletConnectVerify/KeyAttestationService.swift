import Foundation
import DeviceCheck

protocol KeyAttesting {
    func attestKey(keyId: String, clientDataHash: Data) async throws
}

class KeyAttestationService: KeyAttesting {
    // TODO - Add DCAppAttestService handling for iOS 14.0
    // private let service = DCAppAttestService.shared
    
    //    If the method, which accesses a remote Apple server, returns the serverUnavailable error,
    // try attestation again later with the same key. For any other error,
    // discard the key identifier and create a new key when you want to try again.
    // Otherwise, send the completion handler’s attestation object and the keyId to your server for processing.
    func attestKey(keyId: String, clientDataHash: Data) {

        // try await service.attestKey(keyId, clientDataHash: clientDataHash)
        // TODO - Send the attestation object to your server for verification. handle errors

    }

    private func sendAttestationToVerifyServer() async throws {

    }
}
