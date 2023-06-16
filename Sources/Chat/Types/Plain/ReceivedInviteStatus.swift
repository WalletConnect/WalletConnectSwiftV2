import Foundation

struct ReceivedInviteStatus: DatabaseObject {
    let id: Int64
    let status: ReceivedInvite.Status

    var databaseId: String {
        return String(id)
    }
}
