import Foundation

struct InviteKey: DatabaseObject {
    let publicKey: String
    let privateKey: String
    let account: Account

    var topic: String {
        return Data(hex: publicKey).sha256().toHexString()
    }

    var databaseId: String {
        return account.absoluteString
    }
}
