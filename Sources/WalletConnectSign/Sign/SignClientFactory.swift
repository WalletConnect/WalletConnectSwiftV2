import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS
import WalletConnectPairing

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
    public static func create(metadata: AppMetadata, relayClient: RelayClient) -> SignClient {
        let logger = ConsoleLogger(loggingLevel: .off)
        let keyValueStorage = UserDefaults.standard
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        return SignClientFactory.create(metadata: metadata, logger: logger, keyValueStorage: keyValueStorage, keychainStorage: keychainStorage, relayClient: relayClient)
    }

    static func create(metadata: AppMetadata, logger: ConsoleLogging, keyValueStorage: KeyValueStorage, keychainStorage: KeychainStorageProtocol, relayClient: RelayClient) -> SignClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let serializer = Serializer(kms: kms)
        let history = JsonRpcHistory(logger: logger, keyValueStore: CodableStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue))
        let networkingInteractor = NetworkInteractor(relayClient: relayClient, serializer: serializer, logger: logger, jsonRpcHistory: history)
        let pairingStore = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.pairings.rawValue)))
        let sessionStore = SessionStorage(storage: SequenceStore<WCSession>(store: .init(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.sessions.rawValue)))
        let sessionToPairingTopic = CodableStore<String>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.sessionToPairingTopic.rawValue)
        let proposalPayloadsStore = CodableStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: StorageDomainIdentifiers.proposals.rawValue)
        let pairingEngine = PairingEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore, metadata: metadata, logger: logger)
        let sessionEngine = SessionEngine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        let nonControllerSessionStateMachine = NonControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        let controllerSessionStateMachine = ControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: kms, sessionStore: sessionStore, logger: logger)
        let pairEngine = PairEngine(networkingInteractor: networkingInteractor, kms: kms, pairingStore: pairingStore)
        let approveEngine = ApproveEngine(networkingInteractor: networkingInteractor, proposalPayloadsStore: proposalPayloadsStore, sessionToPairingTopic: sessionToPairingTopic, metadata: metadata, kms: kms, logger: logger, pairingStore: pairingStore, sessionStore: sessionStore)
        let cleanupService = CleanupService(pairingStore: pairingStore, sessionStore: sessionStore, kms: kms, sessionToPairingTopic: sessionToPairingTopic)

        let client = SignClient(
            logger: logger,
            relayClient: relayClient,
            pairingEngine: pairingEngine,
            pairEngine: pairEngine,
            sessionEngine: sessionEngine,
            approveEngine: approveEngine,
            nonControllerSessionStateMachine: nonControllerSessionStateMachine,
            controllerSessionStateMachine: controllerSessionStateMachine,
            history: history,
            cleanupService: cleanupService
        )

        return client
    }
}
