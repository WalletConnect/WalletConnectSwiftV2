import Foundation
import WalletConnectUtils
import WalletConnectEcho

public struct WalletPushClientFactory {

    public static func create(networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, echoClient: EchoClient) -> WalletPushClient {
        let logger = ConsoleLogger(loggingLevel: .debug)
        let keyValueStorage = UserDefaults.standard
        
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let groupKeychainService = GroupKeychainStorage(serviceIdentifier: "group.com.walletconnect.sdk")

        return WalletPushClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            groupKeychainStorage: groupKeychainService,
            networkInteractor: networkInteractor,
            pairingRegisterer: pairingRegisterer,
            echoClient: echoClient
        )
    }

    static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, groupKeychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, echoClient: EchoClient) -> WalletPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)

        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)

        let subscriptionStore = CodableStore<PushSubscription>(defaults: keyValueStorage, identifier: PushStorageIdntifiers.pushSubscription)

        let proposeResponder = PushRequestResponder(networkingInteractor: networkInteractor, logger: logger, kms: kms, groupKeychainStorage: groupKeychainStorage, rpcHistory: history, subscriptionsStore: subscriptionStore)

        let pushMessagesRecordsStore = CodableStore<PushMessageRecord>(defaults: keyValueStorage, identifier: PushStorageIdntifiers.pushMessagesRecords)
        let pushMessagesDatabase = PushMessagesDatabase(store: pushMessagesRecordsStore)
        let pushMessageSubscriber = PushMessageSubscriber(networkingInteractor: networkInteractor, pushMessagesDatabase: pushMessagesDatabase, logger: logger)
        let subscriptionProvider = SubscriptionsProvider(store: subscriptionStore)
        let deletePushSubscriptionService = DeletePushSubscriptionService(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushSubscriptionStore: subscriptionStore, pushMessagesDatabase: pushMessagesDatabase)
        let deletePushSubscriptionSubscriber = DeletePushSubscriptionSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, pushSubscriptionStore: subscriptionStore)
        let resubscribeService = PushResubscribeService(networkInteractor: networkInteractor, subscriptionsStorage: subscriptionStore)
        let pushSubscriptionsObserver = PushSubscriptionsObserver(store: subscriptionStore)
        return WalletPushClient(
            logger: logger,
            kms: kms,
            echoClient: echoClient,
            pairingRegisterer: pairingRegisterer,
            proposeResponder: proposeResponder,
            pushMessageSubscriber: pushMessageSubscriber,
            subscriptionsProvider: subscriptionProvider,
            pushMessagesDatabase: pushMessagesDatabase,
            deletePushSubscriptionService: deletePushSubscriptionService,
            deletePushSubscriptionSubscriber: deletePushSubscriptionSubscriber,
            resubscribeService: resubscribeService,
            pushSubscriptionsObserver: pushSubscriptionsObserver
        )
    }
}
