import Foundation

public struct ChatClientFactory {

    static func create() -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let client = HTTPNetworkClient(host: "keys.walletconnect.com")
        let registry = KeyserverRegistryProvider(client: client)
        return ChatClientFactory.create(
            registry: registry,
            relayClient: Relay.instance,
            kms: KeyManagementService(keychain: keychain),
            logger: ConsoleLogger(),
            keyValueStorage: UserDefaults.standard
        )
    }

    public static func create(
        registry: Registry,
        relayClient: RelayClient,
        kms: KeyManagementService,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage
    ) -> ChatClient {
        let topicToRegistryRecordStore = CodableStore<RegistryRecord>(defaults: keyValueStorage, identifier: ChatStorageIdentifiers.topicToInvitationPubKey.rawValue)
        let serialiser = Serializer(kms: kms)
        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serialiser, logger: logger, rpcHistory: rpcHistory)
        let invitePayloadStore = CodableStore<RequestSubscriptionPayload<Invite>>(defaults: keyValueStorage, identifier: ChatStorageIdentifiers.invite.rawValue)
        let registryService = RegistryService(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToRegistryRecordStore: topicToRegistryRecordStore)
        let threadStore = Database<Thread>(keyValueStorage: keyValueStorage, identifier: ChatStorageIdentifiers.threads.rawValue)
        let resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, threadStore: threadStore, logger: logger)
        let invitationHandlingService = InvitationHandlingService(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToRegistryRecordStore: topicToRegistryRecordStore, invitePayloadStore: invitePayloadStore, threadsStore: threadStore)
        let inviteService = InviteService(networkingInteractor: networkingInteractor, kms: kms, threadStore: threadStore, rpcHistory: rpcHistory, logger: logger, registry: registry)
        let leaveService = LeaveService()
        let messagesStore = Database<Message>(keyValueStorage: keyValueStorage, identifier: ChatStorageIdentifiers.messages.rawValue)
        let messagingService = MessagingService(networkingInteractor: networkingInteractor, messagesStore: messagesStore, threadStore: threadStore, logger: logger)

        let client = ChatClient(
            registry: registry,
            registryService: registryService,
            messagingService: messagingService,
            invitationHandlingService: invitationHandlingService,
            inviteService: inviteService,
            leaveService: leaveService,
            resubscriptionService: resubscriptionService,
            kms: kms,
            threadStore: threadStore,
            messagesStore: messagesStore,
            invitePayloadStore: invitePayloadStore,
            socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher
        )

        return client
    }
}
