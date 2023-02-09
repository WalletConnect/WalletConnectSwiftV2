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
    public static func create(metadata: AppMetadata, pairingClient: PairingClient, networkingClient: NetworkingInteractor) -> SignClient {
        let logger = ConsoleLogger(loggingLevel: .debug)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return SignClientFactory.create(metadata: metadata, logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, pairingClient: pairingClient, networkingClient: networkingClient)
    }

    static func create(metadata: AppMetadata, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, pairingClient: PairingClient, networkingClient: NetworkingInteractor) -> SignClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: SignStorageIdentifiers.pairings.rawValue)))
        let sessionStore = SessionStorage(storage: SequenceStore<WCSession>(store: .init(defaults: keyValueStorage, identifier: SignStorageIdentifiers.sessions.rawValue)))
        let proposalPayloadsStore = CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>(defaults: RuntimeKeyValueStorage(), identifier: SignStorageIdentifiers.proposals.rawValue)
        let historyService = HistoryService(history: rpcHistory)
        let sessionEngine = SessionEngine(networkingInteractor: networkingClient, historyService: historyService, kms: kms, sessionStore: sessionStore, logger: logger)
        let nonControllerSessionStateMachine = NonControllerSessionStateMachine(networkingInteractor: networkingClient, kms: kms, sessionStore: sessionStore, logger: logger)
        let controllerSessionStateMachine = ControllerSessionStateMachine(networkingInteractor: networkingClient, kms: kms, sessionStore: sessionStore, logger: logger)
        let sessionTopicToProposal = CodableStore<Session.Proposal>(defaults: RuntimeKeyValueStorage(), identifier: SignStorageIdentifiers.sessionTopicToProposal.rawValue)
        let approveEngine = ApproveEngine(networkingInteractor: networkingClient, proposalPayloadsStore: proposalPayloadsStore, sessionTopicToProposal: sessionTopicToProposal, pairingRegisterer: pairingClient, metadata: metadata, kms: kms, logger: logger, pairingStore: pairingStore, sessionStore: sessionStore)
        let cleanupService = SignCleanupService(pairingStore: pairingStore, sessionStore: sessionStore, kms: kms, sessionTopicToProposal: sessionTopicToProposal, networkInteractor: networkingClient)
        let deleteSessionService = DeleteSessionService(networkingInteractor: networkingClient, kms: kms, sessionStore: sessionStore, logger: logger)
        let disconnectService = DisconnectService(deleteSessionService: deleteSessionService, sessionStorage: sessionStore)
        let sessionPingService = SessionPingService(sessionStorage: sessionStore, networkingInteractor: networkingClient, logger: logger)
        let pairingPingService = PairingPingService(pairingStorage: pairingStore, networkingInteractor: networkingClient, logger: logger)
        let appProposerService = AppProposeService(metadata: metadata, networkingInteractor: networkingClient, kms: kms, logger: logger)

        let client = SignClient(
            logger: logger,
            networkingClient: networkingClient,
            sessionEngine: sessionEngine,
            approveEngine: approveEngine,
            pairingPingService: pairingPingService,
            sessionPingService: sessionPingService,
            nonControllerSessionStateMachine: nonControllerSessionStateMachine,
            controllerSessionStateMachine: controllerSessionStateMachine,
            appProposeService: appProposerService,
            disconnectService: disconnectService,
            historyService: historyService,
            cleanupService: cleanupService,
            pairingClient: pairingClient
        )
        return client
    }
}
