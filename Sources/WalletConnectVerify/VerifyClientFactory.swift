import Foundation
import WalletConnectUtils

@available(iOS 14.0, *)
@available(macOS 11.0, *)
public class VerifyClientFactory {

    public static func create(verifyHost: String) throws -> VerifyClient {
        let originVerifier = OriginVerifier()
        let assertionRegistrer = AssertionRegistrer(verifyHost: verifyHost)
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
        return try VerifyClient(
            originVerifier: originVerifier,
            assertionRegistrer: assertionRegistrer,
            appAttestationRegistrer: appAttestationRegistrer
        )
    }
}
