import Foundation

public struct ChatClientFactory {

    static func create(keyserverUrl: String, relayClient: RelayClient, networkingInteractor: NetworkingInteractor, syncClient: SyncClient) -> ChatClient {
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let keyserverURL = URL(string: keyserverUrl)!
        return ChatClientFactory.create(
            keyserverURL: keyserverURL,
            relayClient: relayClient,
            networkingInteractor: networkingInteractor,
            keychain: keychain,
            logger: ConsoleLogger(loggingLevel: .debug),
            keyValueStorage: UserDefaults.standard,
            syncClient: syncClient
        )
    }

    public static func create(
        keyserverURL: URL,
        relayClient: RelayClient,
        networkingInteractor: NetworkingInteractor,
        keychain: KeychainStorageProtocol,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        syncClient: SyncClient
    ) -> ChatClient {
        let kms = KeyManagementService(keychain: keychain)
        let messageStore = KeyedDatabase<[Message]>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.messages.rawValue)
        let receivedInviteStore = KeyedDatabase<[ReceivedInvite]>(storage: keyValueStorage, identifier: ChatStorageIdentifiers.receivedInvites.rawValue)
        let threadStore: SyncStore<Thread> = SyncStoreFactory.create(name: "chatThreads", syncClient: syncClient)
        let sentInviteDelegate = SentInviteStoreDelegate(networkingInteractor: networkingInteractor, kms: kms)
        let threadDelegate = ThreadStoreDelegate(networkingInteractor: networkingInteractor, kms: kms)
        let sentInviteStore: SyncStore<SentInvite> = SyncStoreFactory.create(name: "chatSentInvites", syncClient: syncClient)
        let chatStorage = ChatStorage(messageStore: messageStore, receivedInviteStore: receivedInviteStore, sentInviteStore: sentInviteStore, threadStore: threadStore, sentInviteStoreDelegate: sentInviteDelegate, threadStoreDelegate: threadDelegate)
        let resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, kms: kms, chatStorage: chatStorage, logger: logger)
        let identityClient = IdentityClientFactory.create(keyserver: keyserverURL, keychain: keychain, logger: logger)
        let invitationHandlingService = InvitationHandlingService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityClient: identityClient, kms: kms, logger: logger, chatStorage: chatStorage)
        let inviteService = InviteService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityClient: identityClient, kms: kms, chatStorage: chatStorage, logger: logger)
        let leaveService = LeaveService()
        let messagingService = MessagingService(keyserverURL: keyserverURL, networkingInteractor: networkingInteractor, identityClient: identityClient, chatStorage: chatStorage, logger: logger)
        let syncRegisterService = SyncRegisterService(syncClient: syncClient)

        let client = ChatClient(
            identityClient: identityClient,
            messagingService: messagingService,
            resubscriptionService: resubscriptionService,
            invitationHandlingService: invitationHandlingService,
            inviteService: inviteService,
            leaveService: leaveService,
            kms: kms,
            chatStorage: chatStorage,
            syncRegisterService: syncRegisterService,
            socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher
        )

        return client
    }
}
