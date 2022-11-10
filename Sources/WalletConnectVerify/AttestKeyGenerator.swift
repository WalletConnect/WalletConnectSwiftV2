import DeviceCheck
import Foundation

protocol AttestKeyGenerating {
    func generateKeys() -> String
}

@available(iOS 14.0, *)
@available(macOS 11.0, *)
class AttestKeyGenerator: AttestKeyGenerating {
    private let service = DCAppAttestService.shared

    func generateKeys() -> String {
        service.generateKey { [unowned self] keyId, error in
            guard error == nil else {
                logger.debug(error!.localizedDescription)
                return
            }

            // Cache keyId for subsequent operations.
        }
        fatalError("not implemented")
    }
}
