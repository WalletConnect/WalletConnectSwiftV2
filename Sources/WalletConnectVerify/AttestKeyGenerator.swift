import DeviceCheck
import Foundation

protocol AttestKeyGenerating {
    func generateKeys() async throws -> String
}

class AttestKeyGenerator: AttestKeyGenerating {
    // TODO - Add DCAppAttestService handling for iOS 14.0
    // private let service = DCAppAttestService.shared
    private let logger: ConsoleLogging
    private let keyIdStorage: CodableStore<String>

    init(logger: ConsoleLogging,
         keyIdStorage: CodableStore<String>
    ) {
        self.logger = logger
        self.keyIdStorage = keyIdStorage
    }

    func generateKeys() async throws -> String {
        // TODO - Add DCAppAttestService handling for iOS 14.0
        // let keyId = try await service.generateKey()
        keyIdStorage.set("keyId", forKey: Constants.keyIdStorageKey)
        return "keyId"
    }
}
