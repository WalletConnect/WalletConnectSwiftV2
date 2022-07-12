import Foundation
import Chat

struct InviteViewModel {
    let invite: Invite

    init(invite: Invite) {
        self.invite = invite
    }

    var title: String {
        return invite.account.absoluteString
    }

    var subtitle: String {
        return invite.message
    }
}
