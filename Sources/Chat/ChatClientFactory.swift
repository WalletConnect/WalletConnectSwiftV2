import Foundation

public struct ChatClientFactory {

    static func create(account: Account) -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        return ChatClientFactory.create(
            account: account,
            keyserverURL: keyserverURL,
            relayClient: Relay.instance,
            keychain: keychain,
            logger: ConsoleLogger(loggingLevel: .debug),
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
        let receivedInviteStore = KeyedDatabase<ReceivedInvite>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.receivedInvites.rawValue)
        let sentInviteStore = KeyedDatabase<SentInvite>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.sentInvites.rawValue)
        let threadStore = KeyedDatabase<Thread>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.threads.rawValue)
        let identityStorage = IdentityStorage(keychain: keychain)
        let chatStorage = ChatStorage(accountService: accountService, messageStore: messageStore, receivedInviteStore: receivedInviteStore, sentInviteStore: sentInviteStore, threadStore: threadStore)
        let resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, accountService: accountService, chatStorage: chatStorage, logger: logger)
        let identityService = IdentityService(keyserverURL: keyserverURL, kms: kms, storage: identityStorage, networkService: identityNetworkService, iatProvader: DefaultIATProvider(), messageFormatter: SIWECacaoFormatter())
        let registryService = RegistryService(identityService: identityService, networkingInteractor: networkingInteractor, kms: kms, logger: logger)
        let invitationHandlingService = InvitationHandlingService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityStorage: identityStorage, identityService: identityService, accountService: accountService, kms: kms, logger: logger, chatStorage: chatStorage)
        let inviteService = InviteService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityStorage: identityStorage, accountService: accountService, kms: kms, chatStorage: chatStorage, logger: logger, registryService: registryService)
        let leaveService = LeaveService()
        let messagingService = MessagingService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityStorage: identityStorage, identityService: identityService, accountService: accountService, chatStorage: chatStorage, logger: logger)

        let client = ChatClient(
            registryService: registryService,
            messagingService: messagingService,
            accountService: accountService,
            resubscriptionService: resubscriptionService,
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
