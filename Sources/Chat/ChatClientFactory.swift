import Foundation

public struct ChatClientFactory {

    static func create(keyserverUrl: String, relayClient: RelayClient, networkingInteractor: NetworkingInteractor, syncClient: SyncClient) -> ChatClient {
        fatalError("fix access group")
        let keychain = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: "")
        let keyserverURL = URL(string: keyserverUrl)!
        return ChatClientFactory.create(
            keyserverURL: keyserverURL,
            relayClient: relayClient,
            networkingInteractor: networkingInteractor,
            keychain: keychain,
            logger: ConsoleLogger(loggingLevel: .debug),
            storage: UserDefaults.standard,
            syncClient: syncClient
        )
    }

    public static func create(
        keyserverURL: URL,
        relayClient: RelayClient,
        networkingInteractor: NetworkingInteractor,
        keychain: KeychainStorageProtocol,
        logger: ConsoleLogging,
        storage: KeyValueStorage,
        syncClient: SyncClient
    ) -> ChatClient {
        let kms = KeyManagementService(keychain: keychain)
        let historyService = HistoryService()
        let messageStore = KeyedDatabase<Message>(storage: storage, identifier: ChatStorageIdentifiers.messages.rawValue)
        let receivedInviteStore = KeyedDatabase<ReceivedInvite>(storage: storage, identifier: ChatStorageIdentifiers.receivedInvites.rawValue)
        let threadStore: SyncStore<Thread> = SyncStoreFactory.create(name: ChatStorageIdentifiers.thread.rawValue, syncClient: syncClient, storage: storage)
        let identityClient = IdentityClientFactory.create(keyserver: keyserverURL, keychain: keychain, logger: logger)
        let inviteKeyDelegate = InviteKeyDelegate(networkingInteractor: networkingInteractor, kms: kms, identityClient: identityClient)
        let sentInviteDelegate = SentInviteStoreDelegate(networkingInteractor: networkingInteractor, kms: kms)
        let threadDelegate = ThreadStoreDelegate(networkingInteractor: networkingInteractor, kms: kms, historyService: historyService)
        let sentInviteStore: SyncStore<SentInvite> = SyncStoreFactory.create(name: ChatStorageIdentifiers.sentInvite.rawValue, syncClient: syncClient, storage: storage)
        let inviteKeyStore: SyncStore<InviteKey> = SyncStoreFactory.create(name: ChatStorageIdentifiers.inviteKey.rawValue, syncClient: syncClient, storage: storage)
        let receivedInviteStatusStore: SyncStore<ReceivedInviteStatus> = SyncStoreFactory.create(name: ChatStorageIdentifiers.receivedInviteStatus.rawValue, syncClient: syncClient, storage: storage)
        let receivedInviteStatusDelegate = ReceiviedInviteStatusDelegate()
        let chatStorage = ChatStorage(kms: kms, messageStore: messageStore, receivedInviteStore: receivedInviteStore, sentInviteStore: sentInviteStore, threadStore: threadStore, inviteKeyStore: inviteKeyStore, receivedInviteStatusStore: receivedInviteStatusStore, historyService: historyService, sentInviteStoreDelegate: sentInviteDelegate, threadStoreDelegate: threadDelegate, inviteKeyDelegate: inviteKeyDelegate, receiviedInviteStatusDelegate: receivedInviteStatusDelegate)
        let resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, kms: kms, logger: logger)
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
