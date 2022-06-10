
import WalletConnectUtils
import Foundation

struct InviteParams: Codable {
    let pubKey: String
    let invite: String
    
    var id: String {
        return pubKey
    }
}

struct InviteResponse: Codable {
    let pubKey: String
}


struct Invite: Codable {
    let message: String
    let account: Account
}

public struct InviteEnvelope: Codable {
    let pubKey: String
    let invite: Invite
}
