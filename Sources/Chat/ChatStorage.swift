import Foundation

struct ChatStorage {

    private let messageStore: KeyedDatabase<Message>
    private let inviteStore: KeyedDatabase<Invite>
    private let threadStore: KeyedDatabase<Thread>

    init(
        messageStore: KeyedDatabase<Message>,
        inviteStore: KeyedDatabase<Invite>,
        threadStore: KeyedDatabase<Thread>
    ) {
        self.messageStore = messageStore
        self.inviteStore = inviteStore
        self.threadStore = threadStore
    }

    // MARK: - Invites

    func getInvite(id: Int64, account: Account) -> Invite? {
        return inviteStore.getElements(for: account.absoluteString)
            .first(where: { $0.id == id })
    }

    func set(invite: Invite, account: Account) {
        inviteStore.set(invite, for: account.absoluteString)
    }

    func getInviteTopic(id: Int64, account: Account) -> String? {
        return getInvites(account: account).first(where: { $0.id == id })?.topic
    }

    func getInvites(account: Account) -> [Invite] {
        return inviteStore.getElements(for: account.absoluteString)
    }

    func delete(invite: Invite, account: Account) {
        inviteStore.delete(invite, for: account.absoluteString)
    }

    // MARK: - Threads

    func getThreads(account: Account) -> [Thread] {
        return threadStore.getElements(for: account.absoluteString)
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
