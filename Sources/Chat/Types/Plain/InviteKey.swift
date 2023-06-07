import Foundation

struct InviteKey: SyncObject {
    let publicKey: String
    let privateKey: String
    let account: Account

    var topic: String {
        return Data(hex: publicKey).sha256().toHexString()
    }

    var syncId: String {
        return account.absoluteString
    }
}
