import DeviceCheck
import Foundation
import WalletConnectUtils

protocol AttestKeyGenerating {
    func generateKeys() async throws -> String
}

@available(iOS 14.0, *)
@available(macOS 11.0, *)
class AttestKeyGenerator: AttestKeyGenerating {
    private let service = DCAppAttestService.shared
    private let logger: ConsoleLogging
    private let keyIdStorage: CodableStore<String>


    init(logger: ConsoleLogging,
         keyIdStorage: CodableStore<String>
    ) {
        self.logger = logger
        self.keyIdStorage = keyIdStorage
    }

    func generateKeys() async throws -> String {
        let keyId = try await service.generateKey()
        keyIdStorage.set(keyId, forKey: Constants.keyIdStorageKey)
        return keyId
    }
}
