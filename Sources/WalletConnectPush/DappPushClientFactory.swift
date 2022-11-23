import Foundation

public struct DappPushClientFactory {

    public static func create(networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer) -> DappPushClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return DappPushClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            networkInteractor: networkInteractor
        )
    }

    static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting) -> DappPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let pushProposer = PushProposer(networkingInteractor: networkInteractor, kms: kms, logger: logger)
        let proposalResponseSubscriber = ProposalResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger)
        return DappPushClient(
            logger: logger,
            kms: kms,
            pushProposer: pushProposer,
            proposalResponseSubscriber: proposalResponseSubscriber
        )
    }
}
