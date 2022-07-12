import WalletConnectUtils
import Foundation

struct InviteResponse: Codable {
    let pubKey: String
}

public struct Invite: Codable, Equatable {
    var id: String {
        return publicKey
    }
    let message: String
    let account: Account
    let publicKey: String
}
