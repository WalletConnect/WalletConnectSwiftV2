import WalletConnectUtils
import Foundation

struct InviteResponse: Codable {
    let pubKey: String
}

public struct Invite: Codable, Equatable {
    public let message: String
    public let account: Account
    public let pubKey: String
}
