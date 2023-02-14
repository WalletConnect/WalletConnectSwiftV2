import Foundation
import WalletConnectChat

struct InviteViewModel {
    let invite: ReceivedInvite

    init(invite: ReceivedInvite) {
        self.invite = invite
    }

    var title: String {
        return invite.inviterAccount.address
    }

    var subtitle: String {
        return invite.message
    }
}
