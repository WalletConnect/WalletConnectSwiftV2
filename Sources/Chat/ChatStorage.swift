import Foundation

struct ChatStorage {

    private let accountService: AccountService
    private let messageStore: KeyedDatabase<Message>
    private let inviteStore: KeyedDatabase<Invite>
    private let threadStore: KeyedDatabase<Thread>

    init(
        accountService: AccountService,
        messageStore: KeyedDatabase<Message>,
        inviteStore: KeyedDatabase<Invite>,
        threadStore: KeyedDatabase<Thread>
    ) {
        self.accountService = accountService
        self.messageStore = messageStore
        self.inviteStore = inviteStore
        self.threadStore = threadStore
    }

    // MARK: - Invites

    func getInvite(id: Int64) -> Invite? {
        return inviteStore.getElements(for: accountKey)
            .first(where: { $0.id == id })
    }

    func set(invite: Invite) {
        inviteStore.set(invite, for: accountKey)
    }

    func getInviteTopic(id: Int64) -> String? {
        return getInvites().first(where: { $0.id == id })?.topic
    }

    func getInvites() -> [Invite] {
        return inviteStore.getElements(for: accountKey)
    }

    func delete(invite: Invite) {
        inviteStore.delete(invite, for: accountKey)
    }

    // MARK: - Threads

    func getThreads() -> [Thread] {
        return threadStore.getElements(for: accountKey)
    }

    func getThread(topic: String) -> Thread? {
        return getThreads().first(where: { $0.topic == topic })
    }

    func set(thread: Thread) {
        threadStore.set(thread, for: accountKey)
    }

    // MARK: - Messages

    func set(message: Message) {
        messageStore.set(message, for: accountKey)
    }

    func getMessages() -> [Message] {
        return messageStore.getElements(for: accountKey)
    }

    func getMessages(topic: String) -> [Message] {
        return messageStore.getElements(for: accountKey).filter { $0.topic == topic }
    }
}

private extension ChatStorage {

    var accountKey: String {
        return accountService.currentAccount.absoluteString
    }
}
