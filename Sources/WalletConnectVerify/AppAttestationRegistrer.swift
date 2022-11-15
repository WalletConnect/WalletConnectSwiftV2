import Foundation
import DeviceCheck
import WalletConnectUtils

@available(iOS 14.0, *)
@available(macOS 11.0, *)
class AppAttestationRegistrer {
    private let keyIdStorageKey = "attested_key_id"
    private let service: DCAppAttestService
    private let logger: ConsoleLogging
    private let keyIdStorage: CodableStore<String>

    let attestKeyGenerator: AttestKeyGenerating
    let attestChallengeProvider: AttestChallengeProviding
    let keyAttestationService: KeyAttesting

    init(logger: ConsoleLogging,
         keyIdStorage: CodableStore<String>,
         attestKeyGenerator: AttestKeyGenerating,
         attestChallengeProvider: AttestChallengeProviding,
         keyAttestationService: KeyAttesting
    ) throws {
        self.service = DCAppAttestService.shared
        self.logger = logger
        self.keyIdStorage = keyIdStorage
        self.attestKeyGenerator = attestKeyGenerator
        self.attestChallengeProvider = attestChallengeProvider
        self.keyAttestationService = keyAttestationService
    }

    func registerAttestationIfNeeded() async throws {
        guard keyIdStorage.get(key: keyIdStorageKey) == nil else { return }
        let keyId = generateKeys()
        let challenge = try await getChallenge()
        let hash = Data(SHA256.hash(data: challenge))
        attestKey(keyId: keyId, clientDataHash: hash)
    }

    private func generateKeys() async throws -> String {
        try await attestKeyGenerator.generateKeys()
    }

    private func getChallenge() async throws {
        try await attestChallengeProvider.getChallenge()
    }

    private func attestKey(keyId: String, clientDataHash: Data) async throws {
        try await keyAttestationService.attestKey(keyId: keyId, clientDataHash: clientDataHash)
    }
}
