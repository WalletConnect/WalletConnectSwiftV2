import Foundation
import WalletConnectChat

struct InviteViewModel: Identifiable {

    let id: Int64
    let title: String
    let subtitle: String
    let showActions: Bool
    let statusTitle: String

    let receivedInvite: ReceivedInvite?
    let sentInvite: SentInvite?

    init(invite: ReceivedInvite) {
        self.id = invite.id
        self.title = invite.inviterAccount.address
        self.subtitle = invite.message
        self.showActions = invite.status == .pending
        self.statusTitle = invite.status.rawValue.capitalized
        self.receivedInvite = invite
        self.sentInvite = nil
    }

    init(invite: SentInvite) {
        self.id = invite.id
        self.title = invite.inviteeAccount.address
        self.subtitle = invite.message
        self.showActions = false
        self.statusTitle = invite.status.rawValue.capitalized
        self.sentInvite = invite
        self.receivedInvite = nil
    }
}
