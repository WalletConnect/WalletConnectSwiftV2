import Foundation

public struct ChatClientFactory {

    static func create(account: Account) -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let client = HTTPNetworkClient(host: "keys.walletconnect.com")
        let registry = KeyserverRegistryProvider(client: client)
        return ChatClientFactory.create(
            account: account,
            registry: registry,
            relayClient: Relay.instance,
            kms: KeyManagementService(keychain: keychain),
            logger: ConsoleLogger(),
            keyValueStorage: UserDefaults.standard
        )
    }

    public static func create(
        account: Account,
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
        let accountService = AccountService(currentAccount: account)
        let messageStore = KeyedDatabase<Message>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.messages.rawValue)
        let inviteStore = KeyedDatabase<Invite>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.invites.rawValue)
        let threadStore = KeyedDatabase<Thread>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.threads.rawValue)
        let chatStorage = ChatStorage(accountService: accountService, messageStore: messageStore, inviteStore: inviteStore, threadStore: threadStore)
        let registryService = RegistryService(registry: registry, accountService: accountService, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToRegistryRecordStore: topicToRegistryRecordStore)
        let resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, chatStorage: chatStorage, logger: logger)
        let invitationHandlingService = InvitationHandlingService(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToRegistryRecordStore: topicToRegistryRecordStore, chatStorage: chatStorage)
        let inviteService = InviteService(networkingInteractor: networkingInteractor, kms: kms, chatStorage: chatStorage, logger: logger, registry: registry)
        let leaveService = LeaveService()
        let messagingService = MessagingService(networkingInteractor: networkingInteractor, chatStorage: chatStorage, logger: logger)

        let client = ChatClient(
            registry: registry,
            registryService: registryService,
            messagingService: messagingService,
            invitationHandlingService: invitationHandlingService,
            inviteService: inviteService,
            leaveService: leaveService,
            resubscriptionService: resubscriptionService,
            kms: kms,
            chatStorage: chatStorage,
            socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher
        )

        return client
    }
}
