import Foundation
import Combine

final class ChatStorage {

    private var publishers = Set<AnyCancellable>()

    private let kms: KeyManagementServiceProtocol
    private let messageStore: KeyedDatabase<Message>
    private let receivedInviteStore: KeyedDatabase<ReceivedInvite>
    private let sentInviteStore: SyncStore<SentInvite>
    private let threadStore: SyncStore<Thread>
    private let inviteKeyStore: SyncStore<InviteKey>
    private let receivedInviteStatusStore: SyncStore<ReceivedInviteStatus>
    private let historyService: HistoryService

    private let sentInviteStoreDelegate: SentInviteStoreDelegate
    private let threadStoreDelegate: ThreadStoreDelegate
    private let inviteKeyDelegate: InviteKeyDelegate
    private let receiviedInviteStatusDelegate: ReceiviedInviteStatusDelegate

    private var messagesPublisherSubject = PassthroughSubject<[Message], Never>()
    private var receivedInvitesPublisherSubject = PassthroughSubject<[ReceivedInvite], Never>()
    private var newMessagePublisherSubject = PassthroughSubject<Message, Never>()
    private var newReceivedInvitePublisherSubject = PassthroughSubject<ReceivedInvite, Never>()
    private var newSentInvitePublisherSubject = PassthroughSubject<SentInvite, Never>()
    private var newThreadPublisherSubject = PassthroughSubject<Thread, Never>()

    private var acceptPublisherSubject = PassthroughSubject<(String, SentInvite), Never>()
    private var rejectPublisherSubject = PassthroughSubject<(SentInvite), Never>()

    var messagesPublisher: AnyPublisher<[Message], Never> {
        messagesPublisherSubject.eraseToAnyPublisher()
    }

    var receivedInvitesPublisher: AnyPublisher<[ReceivedInvite], Never> {
        receivedInvitesPublisherSubject.eraseToAnyPublisher()
    }

    var sentInvitesPublisher: AnyPublisher<[SentInvite], Never> {
        sentInviteStore.dataUpdatePublisher
    }

    var threadsPublisher: AnyPublisher<[Thread], Never> {
        threadStore.dataUpdatePublisher
    }

    var newMessagePublisher: AnyPublisher<Message, Never> {
        newMessagePublisherSubject.eraseToAnyPublisher()
    }

    var newReceivedInvitePublisher: AnyPublisher<ReceivedInvite, Never> {
        newReceivedInvitePublisherSubject.eraseToAnyPublisher()
    }

    var newSentInvitePublisher: AnyPublisher<SentInvite, Never> {
        newSentInvitePublisherSubject.eraseToAnyPublisher()
    }

    var newThreadPublisher: AnyPublisher<Thread, Never> {
        newThreadPublisherSubject.eraseToAnyPublisher()
    }

    var acceptPublisher: AnyPublisher<(String, SentInvite), Never> {
        acceptPublisherSubject.eraseToAnyPublisher()
    }

    var rejectPublisher: AnyPublisher<SentInvite, Never> {
        rejectPublisherSubject.eraseToAnyPublisher()
    }

    init(
        kms: KeyManagementServiceProtocol,
        messageStore: KeyedDatabase<Message>,
        receivedInviteStore: KeyedDatabase<ReceivedInvite>,
        sentInviteStore: SyncStore<SentInvite>,
        threadStore: SyncStore<Thread>,
        inviteKeyStore: SyncStore<InviteKey>,
        receivedInviteStatusStore: SyncStore<ReceivedInviteStatus>,
        historyService: HistoryService,
        sentInviteStoreDelegate: SentInviteStoreDelegate,
        threadStoreDelegate: ThreadStoreDelegate,
        inviteKeyDelegate: InviteKeyDelegate,
        receiviedInviteStatusDelegate: ReceiviedInviteStatusDelegate
    ) {
        self.kms = kms
        self.messageStore = messageStore
        self.receivedInviteStore = receivedInviteStore
        self.sentInviteStore = sentInviteStore
        self.threadStore = threadStore
        self.inviteKeyStore = inviteKeyStore
        self.receivedInviteStatusStore = receivedInviteStatusStore
        self.historyService = historyService
        self.sentInviteStoreDelegate = sentInviteStoreDelegate
        self.threadStoreDelegate = threadStoreDelegate
        self.inviteKeyDelegate = inviteKeyDelegate
        self.receiviedInviteStatusDelegate = receiviedInviteStatusDelegate

        setupSyncSubscriptions()
    }

    // MARK: - Configuration

    func initializeStores(for account: Account) async throws {
        try await sentInviteStore.create(for: account)
        try await threadStore.create(for: account)
        try await inviteKeyStore.create(for: account)
        try await receivedInviteStatusStore.create(for: account)

        try await sentInviteStore.subscribe(for: account)
        try await threadStore.subscribe(for: account)
        try await inviteKeyStore.subscribe(for: account)
        try await receivedInviteStatusStore.subscribe(for: account)
    }

    func initializeDelegates() async throws {
        try await sentInviteStoreDelegate.onInitialization(sentInviteStore.getAll())
        try await threadStoreDelegate.onInitialization(storage: self)
        try await inviteKeyDelegate.onInitialization(inviteKeyStore.getAll())
        try await receiviedInviteStatusDelegate.onInitialization()
    }

    func initializeHistory(account: Account) async throws {
        try await historyService.register()

        for thread in getAllThreads() {
            let messages = try await historyService.fetchMessageHistory(thread: thread)
            set(messages: messages, account: account)
        }
    }

    func setupSubscriptions(account: Account) throws {
        messageStore.onUpdate = { [unowned self] in
            messagesPublisherSubject.send(getMessages(account: account))
        }
        receivedInviteStore.onUpdate = { [unowned self] in
            receivedInvitesPublisherSubject.send(getReceivedInvites(account: account))
        }

        try sentInviteStore.setupDatabaseSubscriptions(account: account)
        try threadStore.setupDatabaseSubscriptions(account: account)
        try inviteKeyStore.setupDatabaseSubscriptions(account: account)
    }

    // MARK: - Invites

    func getReceivedInvite(id: Int64) -> ReceivedInvite? {
        return receivedInviteStore.getAll()
            .first(where: { $0.id == id })
    }

    func getSentInvite(id: Int64) -> SentInvite? {
        return sentInviteStore.getAll()
            .first(where: { $0.id == id })
    }

    func set(receivedInvite: ReceivedInvite, account: Account) {
        receivedInviteStore.set(element: receivedInvite, for: account.absoluteString)
        newReceivedInvitePublisherSubject.send(receivedInvite)
    }

    func set(sentInvite: SentInvite, account: Account) async throws {
        try await sentInviteStore.set(object: sentInvite, for: account)
        newSentInvitePublisherSubject.send(sentInvite)
    }

    func getReceivedInvites(account: Account) -> [ReceivedInvite] {
        return receivedInviteStore.getAll(for: account.absoluteString)
    }

    func syncRejectedReceivedInviteStatus(id: Int64, account: Account) async throws {
        let status = ReceivedInviteStatus(id: id, status: .rejected)
        try await receivedInviteStatusStore.set(object: status, for: account)
    }

    func getReceivedInvites(thread: Thread) -> [ReceivedInvite] {
        return getReceivedInvites(account: thread.selfAccount)
            .filter { $0.inviterAccount == thread.peerAccount }
    }

    func getSentInvites(account: Account) -> [SentInvite] {
        do {
            return try sentInviteStore.getAll(for: account)
        } catch {
            // TODO: remove fatalError
            fatalError(error.localizedDescription)
        }
    }

    func accept(receivedInvite: ReceivedInvite, account: Account) {
        receivedInviteStore.delete(id: receivedInvite.databaseId, for: account.absoluteString)

        let accepted = ReceivedInvite(invite: receivedInvite, status: .approved)
        receivedInviteStore.set(element: accepted, for: account.absoluteString)
    }

    func reject(receivedInvite: ReceivedInvite, account: Account) {
        receivedInviteStore.delete(id: receivedInvite.databaseId, for: account.absoluteString)

        let rejected = ReceivedInvite(invite: receivedInvite, status: .rejected)
        receivedInviteStore.set(element: rejected, for: account.absoluteString)
    }

    func accept(sentInviteId: Int64, topic: String) async throws {
        guard let invite = getSentInvite(id: sentInviteId)
        else { return }

        let approved = SentInvite(invite: invite, status: .approved)
        try await sentInviteStore.set(object: approved, for: invite.inviterAccount)

        acceptPublisherSubject.send((topic, approved))
    }

    func reject(sentInviteId: Int64) async throws {
        guard let invite = getSentInvite(id: sentInviteId)
        else { return }

        let rejected = SentInvite(invite: invite, status: .rejected)
        try await sentInviteStore.set(object: rejected, for: invite.inviterAccount)

        rejectPublisherSubject.send(rejected)
    }

    // MARK: InviteKeys

    func setInviteKey(_ inviteKey: AgreementPublicKey, account: Account) async throws {
        if let privateKey = try kms.getPrivateKey(for: inviteKey) {
            let pubKeyHex = inviteKey.hexRepresentation
            let privKeyHex = privateKey.rawRepresentation.toHexString()
            let key = InviteKey(publicKey: pubKeyHex, privateKey: privKeyHex, account: account)
            try await inviteKeyStore.set(object: key, for: account)
        }
    }

    func removeInviteKey(_ inviteKey: AgreementPublicKey, account: Account) async throws {
        try await inviteKeyStore.delete(id: inviteKey.hexRepresentation, for: account)
    }

    // MARK: - Threads

    func getAllThreads() -> [Thread] {
        return threadStore.getAll()
    }

    func getThreads(account: Account) -> [Thread] {
        do {
            return try threadStore.getAll(for: account)
        } catch {
            // TODO: remove fatalError
            fatalError(error.localizedDescription)
        }
    }

    func getThread(topic: String) -> Thread? {
        return getAllThreads().first(where: { $0.topic == topic })
    }

    func set(thread: Thread, account: Account) async throws {
        try await threadStore.set(object: thread, for: account)
        newThreadPublisherSubject.send(thread)
    }

    // MARK: - Messages

    func set(message: Message, account: Account) {
        messageStore.set(element: message, for: account.absoluteString)
        newMessagePublisherSubject.send(message)
    }

    func set(messages: [Message], account: Account) {
        messageStore.set(elements: messages, for: account.absoluteString)
    }

    func getMessages(topic: String) -> [Message] {
        return messageStore.getAll().filter { $0.topic == topic }
    }

    func getMessages(account: Account) -> [Message] {
        return messageStore.getAll(for: account.absoluteString) 
    }
}

private extension ChatStorage {

    func setupSyncSubscriptions() {
        sentInviteStore.syncUpdatePublisher.sink { [unowned self] topic, account, update in
            switch update {
            case .set(let object), .update(let object):
                self.sentInviteStoreDelegate.onUpdate(object)
            case .delete(let object):
                self.sentInviteStoreDelegate.onDelete(object)
            }
        }.store(in: &publishers)

        threadStore.syncUpdatePublisher.sink { [unowned self] topic, account, update in
            switch update {
            case .set(let object), .update(let object):
                self.threadStoreDelegate.onUpdate(object, storage: self)
            case .delete(let object):
                self.threadStoreDelegate.onDelete(object)
            }
        }.store(in: &publishers)

        inviteKeyStore.syncUpdatePublisher.sink { [unowned self] topic, account, update in
            switch update {
            case .set(let object), .update(let object):
                self.inviteKeyDelegate.onUpdate(object, account: account)
            case .delete(let object):
                self.inviteKeyDelegate.onDelete(object)
            }
        }.store(in: &publishers)

        receivedInviteStatusStore.syncUpdatePublisher.sink { [unowned self] topic, account, update in
            switch update {
            case .set(let object), .update(let object):
                self.receiviedInviteStatusDelegate.onUpdate(object, storage: self, account: account)
            case .delete(let object):
                self.receiviedInviteStatusDelegate.onDelete(object)
            }
        }.store(in: &publishers)
    }
}
