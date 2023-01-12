import Foundation

struct ChatStorage {

    let history: RPCHistory

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
}
