import Foundation

struct ChatStorage {

    private let history: RPCHistory
    private let threadStore: Database<Thread>

    init(history: RPCHistory, threadStore: Database<Thread>) {
        self.history = history
        self.threadStore = threadStore
    }

    // MARK: - Invites

    func getInvite(id: Int64) -> Invite? {
        guard
            let record = history.get(recordId: RPCID(id)),
            let payload = try? record.request.params?.get(InvitePayload.self)
        else { return nil }

        return Invite(id: record.id.integer, payload: payload)
    }

    func getInviteTopic(id: Int64) -> String? {
        return history.get(recordId: RPCID(id))?.topic
    }

    func getInvites() -> [Invite] {
        return history.getAllWithIDs(of: InvitePayload.self)
            .map { Invite(id: $0.id.integer, payload: $0.value) }
    }

    func delete(invite: Invite) {
        history.delete(id: RPCID(invite.id))
    }

    // MARK: - Threads

    func getThreads() -> [Thread] {
        return threadStore.getAll()
    }

    func getThread(topic: String) -> Thread? {
        return getThreads().first(where: { $0.topic == topic })
    }

    func add(thread: Thread) {
        threadStore.add(thread)
    }

    // MARK: - Messages

    func getMessages(topic: String) -> [Message] {
        return history.getAll(of: Message.self).filter { $0.topic == topic }
    }
}
