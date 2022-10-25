import Foundation
import WalletConnectChat

struct InviteViewModel {
    let invite: Invite

    init(invite: Invite) {
        self.invite = invite
    }

    var title: String {
        return AccountNameResolver.resolveName(invite.account)
    }

    var subtitle: String {
        return invite.message
    }
}
