import Foundation

struct ReceivedInviteStatus: Codable, SyncObject {
    let id: Int64
    let status: ReceivedInvite.Status

    var syncId: String {
        return String(id)
    }
}
