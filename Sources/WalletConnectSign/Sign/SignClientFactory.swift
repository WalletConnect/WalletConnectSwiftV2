import Foundation

public struct SignClientFactory {

    /// Initializes and returns newly created WalletConnect Client Instance
    ///
    /// - Parameters:
    ///   - metadata: describes your application and will define pairing appearance in a web browser.
    ///   - projectId: an optional parameter used to access the public WalletConnect infrastructure. Go to `www.walletconnect.com` for info.
    ///   - relayHost: proxy server host that your application will use to connect to Iridium Network. If you register your project at `www.walletconnect.com` you can use `relay.walletconnect.com`
    ///   - keyValueStorage: by default WalletConnect SDK will store sequences in UserDefaults
    ///
    /// WalletConnect Client is not a singleton but once you create an instance, you should not deinitialize it. Usually only one instance of a client is required in the application.
    public static func create(
        metadata: AppMetadata,
        pairingClient: PairingClient,
        projectId: String,
        crypto: CryptoProvider,
        networkingClient: NetworkingInteractor,
        groupIdentifier: String
    ) -> SignClient {
        let logger = ConsoleLogger(prefix: "📝", loggingLevel: .off)

        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Could not instantiate UserDefaults for a group identifier \(groupIdentifier)")
        }
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)

        let iatProvider = DefaultIATProvider()

        return SignClientFactory.create(
            metadata: metadata,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            pairingClient: pairingClient,
            networkingClient: networkingClient,
            iatProvider: iatProvider,
            projectId: projectId,
            crypto: crypto
        )
    }

    static func create(
        metadata: AppMetadata,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        pairingClient: PairingClient,
        networkingClient: NetworkingInteractor,
        iatProvider: IATProvider,
        projectId: String,
        crypto: CryptoProvider
    ) -> SignClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: SignStorageIdentifiers.pairings.rawValue)))
        let sessionStore = SessionStorage(storage: SequenceStore<WCSession>(store: .init(defaults: keyValueStorage, identifier: SignStorageIdentifiers.sessions.rawValue)))
        let proposalPayloadsStore = CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>(defaults: RuntimeKeyValueStorage(), identifier: SignStorageIdentifiers.proposals.rawValue)
        let verifyContextStore = CodableStore<VerifyContext>(defaults: keyValueStorage, identifier: VerifyStorageIdentifiers.context.rawValue)
        let historyService = HistoryService(history: rpcHistory, verifyContextStore: verifyContextStore)
        let verifyClient = VerifyClientFactory.create()
        let sessionRequestsProvider = SessionRequestsProvider(historyService: historyService)
        let sessionEngine = SessionEngine(networkingInteractor: networkingClient, historyService: historyService, verifyContextStore: verifyContextStore, verifyClient: verifyClient, kms: kms, sessionStore: sessionStore, logger: logger, sessionRequestsProvider: sessionRequestsProvider)
        let nonControllerSessionStateMachine = NonControllerSessionStateMachine(networkingInteractor: networkingClient, kms: kms, sessionStore: sessionStore, logger: logger)
        let controllerSessionStateMachine = ControllerSessionStateMachine(networkingInteractor: networkingClient, kms: kms, sessionStore: sessionStore, logger: logger)
        let sessionExtendRequester = SessionExtendRequester(sessionStore: sessionStore, networkingInteractor: networkingClient)
        let sessionExtendRequestSubscriber = SessionExtendRequestSubscriber(networkingInteractor: networkingClient, sessionStore: sessionStore, logger: logger)
        let sessionExtendResponseSubscriber = SessionExtendResponseSubscriber(networkingInteractor: networkingClient, sessionStore: sessionStore, logger: logger)
        let sessionTopicToProposal = CodableStore<Session.Proposal>(defaults: RuntimeKeyValueStorage(), identifier: SignStorageIdentifiers.sessionTopicToProposal.rawValue)
        let authRequestSubscribersTracking = AuthRequestSubscribersTracking(logger: logger)
        let approveEngine = ApproveEngine(
            networkingInteractor: networkingClient,
            proposalPayloadsStore: proposalPayloadsStore,
            verifyContextStore: verifyContextStore,
            sessionTopicToProposal: sessionTopicToProposal,
            pairingRegisterer: pairingClient,
            metadata: metadata,
            kms: kms,
            logger: logger,
            pairingStore: pairingStore,
            sessionStore: sessionStore,
            verifyClient: verifyClient,
            rpcHistory: rpcHistory,
            authRequestSubscribersTracking: authRequestSubscribersTracking
        )
        let cleanupService = SignCleanupService(pairingStore: pairingStore, sessionStore: sessionStore, kms: kms, sessionTopicToProposal: sessionTopicToProposal, networkInteractor: networkingClient, rpcHistory: rpcHistory)
        let deleteSessionService = DeleteSessionService(networkingInteractor: networkingClient, kms: kms, sessionStore: sessionStore, logger: logger)
        let disconnectService = DisconnectService(deleteSessionService: deleteSessionService, sessionStorage: sessionStore)
        let sessionPingService = SessionPingService(sessionStorage: sessionStore, networkingInteractor: networkingClient, logger: logger)
        let pairingPingService = PairingPingService(pairingStorage: pairingStore, networkingInteractor: networkingClient, logger: logger)
        let appProposerService = AppProposeService(metadata: metadata, networkingInteractor: networkingClient, kms: kms, logger: logger)
        let proposalExpiryWatcher = ProposalExpiryWatcher(proposalPayloadsStore: proposalPayloadsStore, rpcHistory: rpcHistory)
        let pendingProposalsProvider = PendingProposalsProvider(proposalPayloadsStore: proposalPayloadsStore, verifyContextStore: verifyContextStore)
        let requestsExpiryWatcher = RequestsExpiryWatcher(proposalPayloadsStore: proposalPayloadsStore, rpcHistory: rpcHistory, historyService: historyService)


        //Auth
        let authResponseTopicRecordsStore = CodableStore<AuthResponseTopicRecord>(defaults: keyValueStorage, identifier: SignStorageIdentifiers.authResponseTopicRecord.rawValue)
        let messageFormatter = SIWEFromCacaoPayloadFormatter()
        let appRequestService = SessionAuthRequestService(networkingInteractor: networkingClient, kms: kms, appMetadata: metadata, logger: logger, iatProvader: iatProvider, authResponseTopicRecordsStore: authResponseTopicRecordsStore)

        let messageVerifierFactory = MessageVerifierFactory(crypto: crypto)
        let signatureVerifier = messageVerifierFactory.create(projectId: projectId)
        let sessionNameSpaceBuilder = SessionNamespaceBuilder(logger: logger)
        let appRespondSubscriber = AuthResponseSubscriber(networkingInteractor: networkingClient, logger: logger, rpcHistory: rpcHistory, signatureVerifier: signatureVerifier, pairingRegisterer: pairingClient, kms: kms, sessionStore: sessionStore, messageFormatter: messageFormatter, sessionNamespaceBuilder: sessionNameSpaceBuilder, authResponseTopicRecordsStore: authResponseTopicRecordsStore)

        let walletErrorResponder = WalletErrorResponder(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: rpcHistory)
        let authRequestSubscriber = AuthRequestSubscriber(networkingInteractor: networkingClient, logger: logger, kms: kms, walletErrorResponder: walletErrorResponder, pairingRegisterer: pairingClient, verifyClient: verifyClient, verifyContextStore: verifyContextStore, pairingStore: pairingStore)
        let authResponder = AuthResponder(networkingInteractor: networkingClient, logger: logger, kms: kms, rpcHistory: rpcHistory, signatureVerifier: signatureVerifier, messageFormatter: messageFormatter, verifyContextStore: verifyContextStore, walletErrorResponder: walletErrorResponder, pairingRegisterer: pairingClient, metadata: metadata, sessionStore: sessionStore, sessionNamespaceBuilder: sessionNameSpaceBuilder)
        let pendingRequestsProvider = PendingRequestsProvider(rpcHistory: rpcHistory, verifyContextStore: verifyContextStore)
        let authResponseTopicResubscriptionService = AuthResponseTopicResubscriptionService(networkingInteractor: networkingClient, logger: logger, authResponseTopicRecordsStore: authResponseTopicRecordsStore)


        let client = SignClient(
            logger: logger,
            networkingClient: networkingClient,
            sessionEngine: sessionEngine,
            approveEngine: approveEngine,
            pairingPingService: pairingPingService,
            sessionPingService: sessionPingService,
            nonControllerSessionStateMachine: nonControllerSessionStateMachine,
            controllerSessionStateMachine: controllerSessionStateMachine,
            sessionExtendRequester: sessionExtendRequester,
            sessionExtendRequestSubscriber: sessionExtendRequestSubscriber,
            sessionExtendResponseSubscriber: sessionExtendResponseSubscriber,
            appProposeService: appProposerService,
            disconnectService: disconnectService,
            historyService: historyService,
            cleanupService: cleanupService,
            pairingClient: pairingClient,
            appRequestService: appRequestService,
            appRespondSubscriber: appRespondSubscriber,
            authRequestSubscriber: authRequestSubscriber,
            authResponder: authResponder,
            pendingRequestsProvider: pendingRequestsProvider,
            proposalExpiryWatcher: proposalExpiryWatcher,
            pendingProposalsProvider: pendingProposalsProvider,
            requestsExpiryWatcher: requestsExpiryWatcher,
            authResponseTopicResubscriptionService: authResponseTopicResubscriptionService,
            authRequestSubscribersTracking: authRequestSubscribersTracking
        )
        return client
    }
}
