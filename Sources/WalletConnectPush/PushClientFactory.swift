import Foundation
import WalletConnectPairing

//public struct PushClientFactory {
//
//    public static func create(metadata: AppMetadata,networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer) -> PushClient {
//        let logger = ConsoleLogger(loggingLevel: .off)
//        let keyValueStorage = UserDefaults.standard
//        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
//        return PushClientFactory.create(
//            metadata: metadata,
//            logger: logger,
//            keyValueStorage: keyValueStorage,
//            keychainStorage: keychainStorage,
//            networkInteractor: networkInteractor,
//            pairingRegisterer: pairingRegisterer
//        )
//    }
//
//    static func create(metadata: AppMetadata, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer) -> PushClient {
//        let kms = KeyManagementService(keychain: keychainStorage)
//        let pushProposer = PushProposer(networkingInteractor: networkInteractor, kms: kms, appMetadata: metadata, logger: logger)
//        let proposalResponseSubscriber = ProposalResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger)
//        let httpClient = HTTPNetworkClient(host: "echo.walletconnect.com")
//        let registerService = PushRegisterService(networkInteractor: networkInteractor, httpClient: httpClient)
//
//        return PushClient(
//            logger: logger,
//            kms: kms,
//            pushProposer: pushProposer,
//            registerService: registerService,
//            proposalResponseSubscriber: proposalResponseSubscriber,
//            pairingRegisterer: pairingRegisterer
//        )
//    }
//}
