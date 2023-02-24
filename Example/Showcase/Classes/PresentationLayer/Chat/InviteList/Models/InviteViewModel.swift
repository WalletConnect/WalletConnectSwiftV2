import Foundation
import WalletConnectChat

struct InviteViewModel: Identifiable {
    let invite: ReceivedInvite

    var id: Int64 {
        return invite.id
    }

    init(invite: ReceivedInvite) {
        self.invite = invite
    }

    var title: String {
        return invite.inviterAccount.address
    }

    var subtitle: String {
        return invite.message
    }

    var showActions: Bool {
        return invite.status == .pending
    }

    var statusTitle: String {
        switch invite.status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
}
