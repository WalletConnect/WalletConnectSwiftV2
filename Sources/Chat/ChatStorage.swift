import Foundation

struct ChatStorage {

    private let messageStore: KeyedDatabase<Message>
    private let receivedInviteStore: KeyedDatabase<ReceivedInvite>
    private let sentInviteStore: KeyedDatabase<SentInvite>
    private let threadStore: KeyedDatabase<Thread>

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

    // MARK: - Invites

    func getReceivedInvite(id: Int64, account: Account) -> ReceivedInvite? {
        return receivedInviteStore.getElements(for: account.absoluteString)
            .first(where: { $0.id == id })
    }

    func set(receivedInvite: ReceivedInvite, account: Account) {
        receivedInviteStore.set(receivedInvite, for: account.absoluteString)
    }

    func getReceivedInvites(account: Account) -> [ReceivedInvite] {
        return receivedInviteStore.getElements(for: account.absoluteString)
    }

    func accept(invite: ReceivedInvite, account: Account) {
        receivedInviteStore.delete(invite, for: account.absoluteString)

        let accepted = ReceivedInvite(invite: invite, status: .approved)
        receivedInviteStore.set(accepted, for: account.absoluteString)
    }

    func reject(invite: ReceivedInvite, account: Account) {
        receivedInviteStore.delete(invite, for: account.absoluteString)

        let rejected = ReceivedInvite(invite: invite, status: .rejected)
        receivedInviteStore.set(rejected, for: account.absoluteString)
    }

    // MARK: - Threads

    func getThreads(account: Account) -> [Thread] {
        return threadStore.getElements(for: account.absoluteString)
    }

    func getThread(topic: String, account: Account) -> Thread? {
        return getThreads(account: account).first(where: { $0.topic == topic })
    }

    func set(thread: Thread, account: Account) {
        threadStore.set(thread, for: account.absoluteString)
    }

    // MARK: - Messages

    func set(message: Message, account: Account) {
        messageStore.set(message, for: account.absoluteString)
    }

    func getMessages(account: Account) -> [Message] {
        return messageStore.getElements(for: account.absoluteString)
    }

    func getMessages(topic: String, account: Account) -> [Message] {
        return messageStore.getElements(for: account.absoluteString).filter { $0.topic == topic }
    }
}
