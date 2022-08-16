import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing

public struct AuthClientFactory {

    public static func create(metadata: AppMetadata, account: Account?, relayClient: RelayClient, logger: ConsoleLogging) -> AuthClient {
        let keyValueStorage = UserDefaults.standard
        let historyStorage = CodableStore<RPCHistory.Record>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue)
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue)))
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let history = RPCHistory(keyValueStore: historyStorage)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serializer, rpcHistory: history)
        let SIWEMessageFormatter = SIWEMessageFormatter()
        let appPairService = AppPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)
        let appRequestService = AppRequestService(networkingInteractor: networkingInteractor, kms: kms, appMetadata: metadata)
        let messageSigner = MessageSigner(signer: Signer())
        let appRespondSubscriber = AppRespondSubscriber(networkingInteractor: networkingInteractor, logger: logger, rpcHistory: history, signatureVerifier: messageSigner, messageFormatter: SIWEMessageFormatter)
        let walletPairService = WalletPairService(networkingInteractor: networkingInteractor, kms: kms, pairingStorage: pairingStore)
        let walletRequestSubscriber = WalletRequestSubscriber(networkingInteractor: networkingInteractor, logger: logger, messageFormatter: SIWEMessageFormatter, address: account?.address)
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
                          pairingStorage: pairingStore, socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher)
    }
}
