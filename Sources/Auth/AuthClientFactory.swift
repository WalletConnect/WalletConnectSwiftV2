import Foundation

public struct AuthClientFactory {

    public static func create(
        metadata: AppMetadata,
        projectId: String,
        crypto: CryptoProvider,
        networkingClient: NetworkingInteractor,
        pairingRegisterer: PairingRegisterer
    ) -> AuthClient {

        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
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
        let messageFormatter = SIWECacaoFormatter()
        let appRequestService = AppRequestService(networkingInteractor: networkingClient, kms: kms, appMetadata: metadata, logger: logger, iatProvader: iatProvider)
        let verifyClient = try? VerifyClientFactory.create(verifyHost: metadata.verifyUrl)
        let messageVerifierFactory = MessageVerifierFactory(crypto: crypto)
        let signatureVerifier = messageVerifierFactory.create(projectId: projectId)
        let appRespondSubscriber = AppRespondSubscriber(networkingInteractor: networkingClient, logger: logger, rpcHistory: history, signatureVerifier: signatureVerifier, pairingRegisterer: pairingRegisterer, messageFormatter: messageFormatter)
        let walletErrorResponder = WalletErrorResponder(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: history)
        let walletRequestSubscriber = WalletRequestSubscriber(networkingInteractor: networkingClient, logger: logger, kms: kms, walletErrorResponder: walletErrorResponder, pairingRegisterer: pairingRegisterer, verifyClient: verifyClient)
        let walletRespondService = WalletRespondService(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: history, walletErrorResponder: walletErrorResponder)
        let pendingRequestsProvider = PendingRequestsProvider(rpcHistory: history)

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
