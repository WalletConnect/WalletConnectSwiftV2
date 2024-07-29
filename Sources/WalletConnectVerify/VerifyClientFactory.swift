import Foundation

public class VerifyClientFactory {
    public static func create() -> VerifyClient {
        let originVerifier = OriginVerifier()
        let assertionRegistrer = AssertionRegistrer()
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keyIdStorage = CodableStore<String>(defaults: keyValueStorage, identifier: VerifyStorageIdentifier.keyId)
        let attestKeyGenerator = AttestKeyGenerator(logger: logger, keyIdStorage: keyIdStorage)
        let attestChallengeProvider = AttestChallengeProvider()
        let keyAttestationService = KeyAttestationService()
        let appAttestationRegistrer = AppAttestationRegistrer(
            logger: logger,
            keyIdStorage: keyIdStorage,
            attestKeyGenerator: attestKeyGenerator,
            attestChallengeProvider: attestChallengeProvider,
            keyAttestationService: keyAttestationService
        )
        let verifyServerPubKeyManagerStore: CodableStore<VerifyServerPublicKey> = CodableStore(defaults: keyValueStorage, identifier: "com.walletconnect.verify")

        let verifyServerPubKeyManager = VerifyServerPubKeyManager(store: verifyServerPubKeyManagerStore)
        let attestationVerifier = AttestationJWTVerifier(verifyServerPubKeyManager: verifyServerPubKeyManager)
        return VerifyClient(
            originVerifier: originVerifier,
            assertionRegistrer: assertionRegistrer,
            appAttestationRegistrer: appAttestationRegistrer,
            attestationVerifier: attestationVerifier
        )
    }
}
