import Foundation

// TODO: Delete after Chat SDK integration
struct Invite{
    let message: String
    let pubKey: String
}

struct InviteViewModel {
    let invite: Invite

    init(invite: Invite) {
        self.invite = invite
    }

    var title: String {
        return invite.pubKey
    }

    var subtitle: String {
        return invite.message
    }
}
