import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing
import WalletConnectNetworking

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
    public static func create(metadata: AppMetadata, relayClient: RelayClient, pairingClient: PairingClient) -> SignClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return SignClientFactory.create(metadata: metadata, logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, relayClient: relayClient, pairingClient: pairingClient)
    }

    static func create(metadata: AppMetadata, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient, pairingClient: PairingClient) -> SignClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let networkingInteractor = NetworkingClient(relayClient: relayClient, serializer: serializer, logger: logger, rpcHistory: rpcHistory)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue)))
        let sessionStore = SessionStorage(storage: SequenceStore<WCSession>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.sessions.rawValue)))
        let sessionToPairingTopic = CodableStore<String>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.sessionToPairingTopic.rawValue)
        let proposalPayloadsStore = CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.proposals.rawValue)
        let sessionEngine = SessionEngine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        let nonControllerSessionStateMachine = NonControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        let controllerSessionStateMachine = ControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        let approveEngine = ApproveEngine(networkingInteractor: networkingInteractor, proposalPayloadsStore: proposalPayloadsStore, sessionToPairingTopic: sessionToPairingTopic, pairingRegisterer: pairingClient, metadata: metadata, kms: kms, logger: logger, pairingStore: pairingStore, sessionStore: sessionStore)
        let cleanupService = CleanupService(pairingStore: pairingStore, sessionStore: sessionStore, kms: kms, sessionToPairingTopic: sessionToPairingTopic)
        let deleteSessionService = DeleteSessionService(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        let disconnectService = DisconnectService(deleteSessionService: deleteSessionService, sessionStorage: sessionStore, pairingClient: pairingClient)
        let sessionPingService = SessionPingService(sessionStorage: sessionStore, networkingInteractor: networkingInteractor, logger: logger)
        let pairingPingService = PairingPingService(pairingStorage: pairingStore, networkingInteractor: networkingInteractor, logger: logger)
        let appProposerService = AppProposeService(metadata: metadata, networkingInteractor: networkingInteractor, kms: kms, logger: logger)

        let client = SignClient(
            logger: logger,
            relayClient: relayClient,
            sessionEngine: sessionEngine,
            approveEngine: approveEngine,
            pairingPingService: pairingPingService,
            sessionPingService: sessionPingService,
            nonControllerSessionStateMachine: nonControllerSessionStateMachine,
            controllerSessionStateMachine: controllerSessionStateMachine,
            appProposeService: appProposerService,
            disconnectService: disconnectService,
            history: rpcHistory,
            cleanupService: cleanupService,
            pairingClient: pairingClient
        )
        return client
    }
}
