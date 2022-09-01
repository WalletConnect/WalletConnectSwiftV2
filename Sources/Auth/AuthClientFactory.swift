import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing
import WalletConnectNetworking

public struct AuthClientFactory {

    public static func create(metadata: AppMetadata, account: Account?, relayClient: RelayClient) -> AuthClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return AuthClientFactory.create(metadata: metadata, account: account, logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, relayClient: relayClient)
    }

    static func create(metadata: AppMetadata, account: Account?, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient) -> AuthClient {
        let historyStorage = CodableStore<RPCHistory.Record>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue)))
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let history = RPCHistory(keyValueStore: historyStorage)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: history)
        let messageFormatter = SIWEMessageFormatter()
        let appPairService = AppPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)
        let appRequestService = AppRequestService(networkingInteractor: networkingInteractor, kms: kms, appMetadata: metadata, logger: logger)
        let messageSigner = MessageSigner(signer: Signer())
        let appRespondSubscriber = AppRespondSubscriber(networkingInteractor: networkingInteractor, logger: logger, rpcHistory: history, signatureVerifier: messageSigner, messageFormatter: messageFormatter, pairingStorage: pairingStore)
        let walletPairService = WalletPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)
        let walletRequestSubscriber = WalletRequestSubscriber(networkingInteractor: networkingInteractor, logger: logger, kms: kms, messageFormatter: messageFormatter, address: account?.address)
        let walletRespondService = WalletRespondService(networkingInteractor: networkingInteractor, logger: logger, kms: kms, rpcHistory: history)
        let pendingRequestsProvider = PendingRequestsProvider(rpcHistory: history)
        let cleanupService = CleanupService(pairingStore: pairingStore, kms: kms)

        return AuthClient(appPairService: appPairService,
                          appRequestService: appRequestService,
                          appRespondSubscriber: appRespondSubscriber,
                          walletPairService: walletPairService,
                          walletRequestSubscriber: walletRequestSubscriber,
                          walletRespondService: walletRespondService,
                          account: account,
                          pendingRequestsProvider: pendingRequestsProvider,
                          cleanupService: cleanupService,
                          logger: logger,
                          pairingStorage: pairingStore,
                          socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher)
    }
}
