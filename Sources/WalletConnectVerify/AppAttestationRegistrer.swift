import Foundation
import DeviceCheck
import CryptoKit

class AppAttestationRegistrer {
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
    ) {
        self.logger = logger
        self.keyIdStorage = keyIdStorage
        self.attestKeyGenerator = attestKeyGenerator
        self.attestChallengeProvider = attestChallengeProvider
        self.keyAttestationService = keyAttestationService
    }

    func registerAttestationIfNeeded() async throws {
        if let _ = try? keyIdStorage.get(key: Constants.keyIdStorageKey) { return }
        let keyId = try await generateKeys()
        let challenge = try await getChallenge()
        let hash = Data(SHA256.hash(data: challenge))
        try await attestKey(keyId: keyId, clientDataHash: hash)
    }

    private func generateKeys() async throws -> String {
        try await attestKeyGenerator.generateKeys()
    }

    private func getChallenge() async throws -> Data {
        try await attestChallengeProvider.getChallenge()
    }

    private func attestKey(keyId: String, clientDataHash: Data) async throws {
        try await keyAttestationService.attestKey(keyId: keyId, clientDataHash: clientDataHash)
    }
}
