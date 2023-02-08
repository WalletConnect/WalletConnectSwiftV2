
import Foundation
import WalletConnectPush

struct PushMessageViewModel {
    let pushMessageRecord: WalletConnectPush.PushMessageRecord

    var imageUrl: String {
        return pushMessageRecord.message.icon
    }

    var title: String {
        return pushMessageRecord.message.title
    }

    var subtitle: String {
        return pushMessageRecord.message.body
    }
}
