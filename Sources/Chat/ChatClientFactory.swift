import Foundation

public struct ChatClientFactory {

    static func create(account: Account) -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let keyserverURL = URL(string: "https://staging.keys.walletconnect.com")!
        return ChatClientFactory.create(
            account: account,
            keyserverURL: keyserverURL,
            relayClient: Relay.instance,
            keychain: keychain,
            logger: ConsoleLogger(),
            keyValueStorage: UserDefaults.standard
        )
    }

    public static func create(
        account: Account,
        keyserverURL: URL,
        relayClient: RelayClient,
        keychain: KeychainStorageProtocol,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage
    ) -> ChatClient {
        let accountService = AccountService(currentAccount: account)
        let httpService = HTTPNetworkClient(host: keyserverURL.host!)
        let identityNetworkService = IdentityNetworkService(accountService: accountService, httpService: httpService)
        let kms = KeyManagementService(keychain: keychain)
        let serialiser = Serializer(kms: kms)
        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serialiser, logger: logger, rpcHistory: rpcHistory)
        let messageStore = KeyedDatabase<Message>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.messages.rawValue)
        let inviteStore = KeyedDatabase<Invite>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.invites.rawValue)
        let threadStore = KeyedDatabase<Thread>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.threads.rawValue)
        let identityStorage = IdentityStorage(keychain: keychain)
        let chatStorage = ChatStorage(messageStore: messageStore, inviteStore: inviteStore, threadStore: threadStore)
        let resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, accountService: accountService, chatStorage: chatStorage, logger: logger)
        let identityService = IdentityService(keyserverURL: keyserverURL, kms: kms, storage: identityStorage, networkService: identityNetworkService, iatProvader: DefaultIATProvider(), messageFormatter: SIWECacaoFormatter())
        let registryService = RegistryService(identityService: identityService, accountService: accountService, resubscriptionService: resubscriptionService, networkingInteractor: networkingInteractor, kms: kms, logger: logger)
        let invitationHandlingService = InvitationHandlingService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityStorage: identityStorage, accountService: accountService, kms: kms, logger: logger, chatStorage: chatStorage)
        let inviteService = InviteService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityStorage: identityStorage, accountService: accountService, kms: kms, chatStorage: chatStorage, logger: logger, registryService: registryService)
        let leaveService = LeaveService()
        let messagingService = MessagingService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityStorage: identityStorage, accountService: accountService, chatStorage: chatStorage, logger: logger)

        let client = ChatClient(
            registryService: registryService,
            messagingService: messagingService,
            accountService: accountService,
            invitationHandlingService: invitationHandlingService,
            inviteService: inviteService,
            leaveService: leaveService,
            kms: kms,
            chatStorage: chatStorage,
            socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher
        )

        return client
    }
}
