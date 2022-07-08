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
