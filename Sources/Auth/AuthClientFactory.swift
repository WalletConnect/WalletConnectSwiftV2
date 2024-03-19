import Foundation

public struct AuthClientFactory {
    public static func create(
        metadata: AppMetadata,
        projectId: String,
        crypto: CryptoProvider,
        networkingClient: NetworkingInteractor,
        pairingRegisterer: PairingRegisterer,
        groupIdentifier: String
    ) -> AuthClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Could not instantiate UserDefaults for a group identifier \(groupIdentifier)")
        }
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)
        let iatProvider = DefaultIATProvider()

        return AuthClientFactory.create(
            metadata: metadata,
            projectId: projectId,
            crypto: crypto,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            networkingClient: networkingClient,
            pairingRegisterer: pairingRegisterer,
            iatProvider: iatProvider
        )
    }

    static func create(
        metadata: AppMetadata,
        projectId: String,
        crypto: CryptoProvider,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        networkingClient: NetworkingInteractor,
        pairingRegisterer: PairingRegisterer,
        iatProvider: IATProvider
    ) -> AuthClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let history = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let messageFormatter = SIWEFromCacaoPayloadFormatter()
        let appRequestService = AppRequestService(networkingInteractor: networkingClient, kms: kms, appMetadata: metadata, logger: logger, iatProvader: iatProvider)
        let verifyClient = VerifyClientFactory.create()
        let verifyContextStore = CodableStore<VerifyContext>(defaults: keyValueStorage, identifier: VerifyStorageIdentifiers.context.rawValue)
        let messageVerifierFactory = MessageVerifierFactory(crypto: crypto)
        let signatureVerifier = messageVerifierFactory.create(projectId: projectId)
        let appRespondSubscriber = AppRespondSubscriber(networkingInteractor: networkingClient, logger: logger, rpcHistory: history, signatureVerifier: signatureVerifier, pairingRegisterer: pairingRegisterer, messageFormatter: messageFormatter)
        let walletErrorResponder = Auth_WalletErrorResponder(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: history)
        let walletRequestSubscriber = WalletRequestSubscriber(networkingInteractor: networkingClient, logger: logger, kms: kms, walletErrorResponder: walletErrorResponder, pairingRegisterer: pairingRegisterer, verifyClient: verifyClient, verifyContextStore: verifyContextStore)
        let walletRespondService = WalletRespondService(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: history, verifyContextStore: verifyContextStore, walletErrorResponder: walletErrorResponder, pairingRegisterer: pairingRegisterer)
        let pendingRequestsProvider = Auth_PendingRequestsProvider(rpcHistory: history, verifyContextStore: verifyContextStore)

        return AuthClient(
            appRequestService: appRequestService,
            appRespondSubscriber: appRespondSubscriber,
            walletRequestSubscriber: walletRequestSubscriber,
            walletRespondService: walletRespondService,
            pendingRequestsProvider: pendingRequestsProvider,
            logger: logger,
            socketConnectionStatusPublisher: networkingClient.socketConnectionStatusPublisher,
            pairingRegisterer: pairingRegisterer
        )
    }
}
