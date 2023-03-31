import Foundation
import Combine

final class ChatStorage {

    private let messageStore: KeyedDatabase<Message>
    private let receivedInviteStore: KeyedDatabase<ReceivedInvite>
    private let sentInviteStore: KeyedDatabase<SentInvite>
    private let threadStore: KeyedDatabase<Thread>

    private var messagesPublisherSubject = PassthroughSubject<[Message], Never>()
    private var receivedInvitesPublisherSubject = PassthroughSubject<[ReceivedInvite], Never>()
    private var sentInvitesPublisherSubject = PassthroughSubject<[SentInvite], Never>()
    private var threadsPublisherSubject = PassthroughSubject<[Thread], Never>()

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
        sentInvitesPublisherSubject.eraseToAnyPublisher()
    }

    var threadsPublisher: AnyPublisher<[Thread], Never> {
        threadsPublisherSubject.eraseToAnyPublisher()
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
        messageStore: KeyedDatabase<Message>,
        receivedInviteStore: KeyedDatabase<ReceivedInvite>,
        sentInviteStore: KeyedDatabase<SentInvite>,
        threadStore: KeyedDatabase<Thread>
    ) {
        self.messageStore = messageStore
        self.receivedInviteStore = receivedInviteStore
        self.sentInviteStore = sentInviteStore
        self.threadStore = threadStore
    }

    func setupSubscriptions(account: Account) {
        messageStore.onUpdate = { [unowned self] in
            messagesPublisherSubject.send(getMessages(account: account))
        }
        receivedInviteStore.onUpdate = { [unowned self] in
            receivedInvitesPublisherSubject.send(getReceivedInvites(account: account))
        }
        sentInviteStore.onUpdate = { [unowned self] in
            sentInvitesPublisherSubject.send(getSentInvites(account: account))
        }
        threadStore.onUpdate = { [unowned self] in
            threadsPublisherSubject.send(getThreads(account: account))
        }
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
        receivedInviteStore.set(receivedInvite, for: account.absoluteString)
        newReceivedInvitePublisherSubject.send(receivedInvite)
    }

    func set(sentInvite: SentInvite, account: Account) {
        sentInviteStore.set(sentInvite, for: account.absoluteString)
        newSentInvitePublisherSubject.send(sentInvite)
    }

    func getReceivedInvites(account: Account) -> [ReceivedInvite] {
        return receivedInviteStore.getElements(for: account.absoluteString)
    }

    func getSentInvites(account: Account) -> [SentInvite] {
        return sentInviteStore.getElements(for: account.absoluteString)
    }

    func accept(receivedInvite: ReceivedInvite, account: Account) {
        receivedInviteStore.delete(receivedInvite, for: account.absoluteString)

        let accepted = ReceivedInvite(invite: receivedInvite, status: .approved)
        receivedInviteStore.set(accepted, for: account.absoluteString)
    }

    func reject(receivedInvite: ReceivedInvite, account: Account) {
        receivedInviteStore.delete(receivedInvite, for: account.absoluteString)

        let rejected = ReceivedInvite(invite: receivedInvite, status: .rejected)
        receivedInviteStore.set(rejected, for: account.absoluteString)
    }

    func accept(sentInviteId: Int64, account: Account, topic: String) {
        guard let invite = getSentInvite(id: sentInviteId)
        else { return }

        sentInviteStore.delete(invite, for: account.absoluteString)

        let approved = SentInvite(invite: invite, status: .approved)
        sentInviteStore.set(approved, for: account.absoluteString)

        acceptPublisherSubject.send((topic, approved))
    }

    func reject(sentInviteId: Int64, account: Account) {
        guard let invite = getSentInvite(id: sentInviteId)
        else { return }

        sentInviteStore.delete(invite, for: account.absoluteString)

        let rejected = SentInvite(invite: invite, status: .rejected)
        // TODO: Update also for peer invites
        sentInviteStore.set(rejected, for: account.absoluteString)

        rejectPublisherSubject.send(rejected)
    }

    // MARK: - Threads

    func getAllThreads() -> [Thread] {
        return threadStore.getAll()
    }

    func getThreads(account: Account) -> [Thread] {
        return threadStore.getElements(for: account.absoluteString)
    }

    func getThread(topic: String) -> Thread? {
        return getAllThreads().first(where: { $0.topic == topic })
    }

    func set(thread: Thread, account: Account) {
        threadStore.set(thread, for: account.absoluteString)
        newThreadPublisherSubject.send(thread)
    }

    // MARK: - Messages

    func set(message: Message, account: Account) {
        messageStore.set(message, for: account.absoluteString)
        newMessagePublisherSubject.send(message)
    }

    func getMessages(topic: String) -> [Message] {
        return messageStore.getAll().filter { $0.topic == topic }
    }

    func getMessages(account: Account) -> [Message] {
        return messageStore.getElements(for: account.absoluteString)
    }
}
