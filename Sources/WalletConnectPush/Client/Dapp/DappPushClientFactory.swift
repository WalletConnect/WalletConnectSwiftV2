import Foundation
import WalletConnectPairing

public struct DappPushClientFactory {

    public static func create(metadata: AppMetadata, networkInteractor: NetworkInteracting) -> DappPushClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return DappPushClientFactory.create(
            metadata: metadata,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            networkInteractor: networkInteractor
        )
    }

    static func create(metadata: AppMetadata, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting) -> DappPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let pushProposer = PushProposer(networkingInteractor: networkInteractor, kms: kms, appMetadata: metadata, logger: logger)
        let subscriptionStore = CodableStore<PushSubscription>(defaults: keyValueStorage, identifier: PushStorageIdntifiers.pushSubscription)
        let proposalResponseSubscriber = ProposalResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, metadata: metadata, relay: RelayProtocolOptions(protocol: "irn", data: nil), subscriptionsStore: subscriptionStore)
        let pushMessageSender = PushMessageSender(networkingInteractor: networkInteractor, kms: kms, logger: logger)
        let subscriptionProvider = SubscriptionsProvider(store: subscriptionStore)
        let deletePushSubscriptionService = DeletePushSubscriptionService(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushSubscriptionStore: subscriptionStore)
        let deletePushSubscriptionSubscriber = DeletePushSubscriptionSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushSubscriptionStore: subscriptionStore)
        let resubscribeService = PushResubscribeService(networkInteractor: networkInteractor, subscriptionsStorage: subscriptionStore)
        return DappPushClient(
            logger: logger,
            kms: kms,
            pushProposer: pushProposer,
            proposalResponseSubscriber: proposalResponseSubscriber,
            pushMessageSender: pushMessageSender,
            subscriptionsProvider: subscriptionProvider,
            deletePushSubscriptionService: deletePushSubscriptionService,
            deletePushSubscriptionSubscriber: deletePushSubscriptionSubscriber,
            resubscribeService: resubscribeService
        )
    }
}
