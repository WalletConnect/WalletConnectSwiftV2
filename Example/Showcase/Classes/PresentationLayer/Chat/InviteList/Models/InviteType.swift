import Foundation

enum InviteType {
    case received
    case sent

    var title: String {
        switch self {
        case .received:
            return "Chat Requests"
        case .sent:
            return "Sent Invites"
        }
    }
}
