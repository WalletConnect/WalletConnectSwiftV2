import WalletConnectUtils
import Foundation

struct InviteResponse: Codable {
    let publicKey: String
}

public struct Invite: Codable, Equatable {
    public var id: String {
        return publicKey
    }
    public let message: String
    public let account: Account
    public let publicKey: String
}
