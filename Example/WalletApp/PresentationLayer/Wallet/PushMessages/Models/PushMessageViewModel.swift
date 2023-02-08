
import Foundation
import WalletConnectPush

struct PushMessageViewModel {
    let pushMessage: WalletConnectPush.PushMessage

    var imageUrl: String {
        return pushMessage.icon
    }

    var title: String {
        return pushMessage.title
    }

    var subtitle: String {
        return pushMessage.body
    }
}
