import DeviceCheck
import Foundation

protocol AttestKeyGenerating {
    func generateKeys() async throws -> String
}

@available(iOS 14.0, *)
@available(macOS 11.0, *)
class AttestKeyGenerator: AttestKeyGenerating {
    private let service = DCAppAttestService.shared

    func generateKeys() async throws -> String {
        try await service.generateKey()
        //TODO Cache keyId for subsequent operations.
    }
}
