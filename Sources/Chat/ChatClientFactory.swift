import Foundation

public struct ChatClientFactory {

    static func create(account: Account, relayClient: RelayClient, networkClient: NetworkingInteractor) -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.showcase")
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        return ChatClientFactory.create(
            account: account,
            keyserverURL: keyserverURL,
            relayClient: relayClient,
            networkClient: networkClient,
            keychain: keychain,
            logger: ConsoleLogger(loggingLevel: .debug),
            keyValueStorage: UserDefaults.standard
        )
    }

    public static func create(
        account: Account,
        keyserverURL: URL,
        relayClient: RelayClient,
        networkClient: NetworkingInteractor,
        keychain: KeychainStorageProtocol,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage
    ) -> ChatClient {
        let accountService = AccountService(currentAccount: account)
        let kms = KeyManagementService(keychain: keychain)
        let messageStore = KeyedDatabase<Message>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.messages.rawValue)
        let receivedInviteStore = KeyedDatabase<ReceivedInvite>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.receivedInvites.rawValue)
        let sentInviteStore = KeyedDatabase<SentInvite>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.sentInvites.rawValue)
        let threadStore = KeyedDatabase<Thread>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.threads.rawValue)
        let chatStorage = ChatStorage(accountService: accountService, messageStore: messageStore, receivedInviteStore: receivedInviteStore, sentInviteStore: sentInviteStore, threadStore: threadStore)
        let resubscriptionService = ResubscriptionService(networkClient: networkClient, accountService: accountService, chatStorage: chatStorage, logger: logger)
        let identityClient = IdentityClientFactory.create(keyserver: keyserverURL, networkClient: networkClient, keychain: keychain, logger: logger)
        let invitationHandlingService = InvitationHandlingService(keyserverURL: keyserverURL, networkClient: networkClient, identityClient: identityClient, accountService: accountService, kms: kms, logger: logger, chatStorage: chatStorage)
        let inviteService = InviteService(keyserverURL: keyserverURL, networkClient: networkClient, identityClient: identityClient, accountService: accountService, kms: kms, chatStorage: chatStorage, logger: logger)
        let leaveService = LeaveService()
        let messagingService = MessagingService(keyserverURL: keyserverURL, networkClient: networkClient, identityClient: identityClient, accountService: accountService, chatStorage: chatStorage, logger: logger)

        let client = ChatClient(
            identityClient: identityClient,
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
