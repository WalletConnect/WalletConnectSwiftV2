import Foundation

final class PushSyncService {

    private let syncClient: SyncClient
    private let historyClient: HistoryClient
    private let logger: ConsoleLogging
    private let subscriptionsStore: SyncStore<PushSubscription>
    private let messagesStore: KeyedDatabase<PushMessageRecord>
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let coldStartStore: CodableStore<Date>
    private let groupKeychainStorage: KeychainStorageProtocol

    init(
        syncClient: SyncClient,
        logger: ConsoleLogging,
        historyClient: HistoryClient,
        subscriptionsStore: SyncStore<PushSubscription>,
        messagesStore: KeyedDatabase<PushMessageRecord>,
        networkingInteractor: NetworkInteracting,
        kms: KeyManagementServiceProtocol,
        coldStartStore: CodableStore<Date>,
        groupKeychainStorage: KeychainStorageProtocol
    ) {
        self.syncClient = syncClient
        self.logger = logger
        self.historyClient = historyClient
        self.subscriptionsStore = subscriptionsStore
        self.messagesStore = messagesStore
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.coldStartStore = coldStartStore
        self.groupKeychainStorage = groupKeychainStorage
    }

    func registerSyncIfNeeded(account: Account, onSign: @escaping SigningCallback) async throws {
        guard !syncClient.isRegistered(account: account) else { return }

        let result = await onSign(syncClient.getMessage(account: account))

        switch result {
        case .signed(let signature):
            try await syncClient.register(account: account, signature: signature)
            logger.debug("Sync pushSubscriptions store registered and initialized")
        case .rejected:
            throw PushError.registerSignatureRejected
        }
    }

    func fetchHistoryIfNeeded(account: Account) async throws {
        guard try isColdStart(account: account) else { return }

        try await historyClient.register(tags: [
            "5000", // sync_set
            "5002", // sync_delete
            "4002"  // push_message
        ])

        let syncTopic = try subscriptionsStore.getStoreTopic(account: account)

        let updates: [StoreSetDelete] = try await historyClient.getMessages(
            topic: syncTopic,
            count: 200,
            direction: .backward
        )

        let inserts: [PushSubscription] = updates.compactMap { update in
            guard let value = update.value else { return nil }
            return try? JSONDecoder().decode(PushSubscription.self, from: Data(value.utf8))
        }

        let deletions: [String] = updates.compactMap { update in
            guard update.value == nil else { return nil }
            return update.key
        }

        let subscriptions = inserts.filter { !deletions.contains( $0.databaseId ) }

        try subscriptionsStore.setInStore(objects: subscriptions, for: account)

        for subscription in subscriptions {
            let symmetricKey = try SymmetricKey(hex: subscription.symKey)
            try kms.setSymmetricKey(symmetricKey, for: subscription.topic)
            try groupKeychainStorage.add(symmetricKey, forKey: subscription.topic)
            try await networkingInteractor.subscribe(topic: subscription.topic)

            let historyRecords: [HistoryRecord<PushMessage>] = try await historyClient.getRecords(
                topic: subscription.topic,
                count: 200,
                direction: .backward
            )

            let messageRecords = historyRecords.map { record in
                return PushMessageRecord(
                    id: record.id.string,
                    topic: subscription.topic,
                    message: record.object,
                    publishedAt: Date()
                )
            }

            messagesStore.set(elements: messageRecords, for: subscription.topic)
        }

        coldStartStore.set(Date(), forKey: account.absoluteString)
    }
}

private extension PushSyncService {

    struct StoreSetDelete: Codable, Equatable {
        let key: String
        let value: String?
    }

    func isColdStart(account: Account) throws -> Bool {
        guard let lastFetch = try coldStartStore.get(key: account.absoluteString) else {
            return true
        }
        guard let days = Calendar.current.dateComponents([.day], from: lastFetch, to: Date()).day else {
            return true
        }

        return days >= 30
    }
}
