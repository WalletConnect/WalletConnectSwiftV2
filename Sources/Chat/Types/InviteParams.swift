
import WalletConnectUtils
import Foundation

struct InviteParams: Codable {
    let pubKey: String
    let invite: String
    
    var id: String {
        return pubKey
    }
}


struct Invite: Codable {
    let message: String
    let account: Account
}
