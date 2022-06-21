import WalletConnectUtils
import Foundation

struct InviteParams: Codable, Equatable {
    let pubKey: String
    let invite: Invite

    var id: String {
        return pubKey
    }
}

struct InviteResponse: Codable {
    let pubKey: String
}

struct Invite: Codable, Equatable {
    let message: String
    let account: Account
}

public struct InviteEnvelope: Codable {
    let pubKey: String
    let invite: Invite
}
