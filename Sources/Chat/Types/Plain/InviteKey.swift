import Foundation

struct InviteKey: SyncObject {
    let publicKey: String
    let privateKey: String

    var topic: String {
        return Data(hex: publicKey).sha256().toHexString()
    }

    var syncId: String {
        return publicKey
    }
}
