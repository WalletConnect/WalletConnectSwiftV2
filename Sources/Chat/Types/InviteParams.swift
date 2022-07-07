import WalletConnectUtils
import Foundation

struct InviteResponse: Codable {
    let pubKey: String
}

public struct Invite: Codable, Equatable {
    let message: String
    let account: Account
    let pubKey: String
}

public struct InviteEnvelope: Codable {
    let pubKey: String
    let invite: Invite
}
