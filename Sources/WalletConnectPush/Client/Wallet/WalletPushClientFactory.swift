import Foundation
import WalletConnectUtils
import WalletConnectEcho

public struct WalletPushClientFactory {

    public static func create(networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, echoClient: EchoClient) -> WalletPushClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return WalletPushClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            networkInteractor: networkInteractor,
            pairingRegisterer: pairingRegisterer,
            echoClient: echoClient
        )
    }

    static func create(logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, echoClient: EchoClient) -> WalletPushClient {
        let kms = KeyManagementService(keychain: keychainStorage)

        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)

        let proposeResponder = PushRequestResponder(networkingInteractor: networkInteractor, logger: logger, kms: kms, rpcHistory: history)

        let pushMessageSubscriber = PushMessageSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger)
        let subscriptionStore = CodableStore<PushSubscription>(defaults: keyValueStorage, identifier: PushStorageIdntifiers.pushSubscription)
        let subscriptionProvider = SubscriptionsProvider(store: subscriptionStore)

        return WalletPushClient(
            logger: logger,
            kms: kms,
            echoClient: echoClient,
            pairingRegisterer: pairingRegisterer,
            proposeResponder: proposeResponder,
            pushMessageSubscriber: pushMessageSubscriber,
            subscriptionsProvider: subscriptionProvider
        )
    }
}
