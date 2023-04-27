
import Foundation
import WalletConnectPush

struct PushMessageViewModel: Identifiable {

    let pushMessageRecord: WalletConnectPush.PushMessageRecord

    var id: String {
        return pushMessageRecord.id
    }
    
    var imageUrl: String {
        return pushMessageRecord.message.icon
    }

    var title: String {
        return pushMessageRecord.message.title
    }

    var subtitle: String {
        return pushMessageRecord.message.body
    }
    
    var publishedAt: String {
        return pushMessageRecord.publishedAt.formatted(.relative(presentation: .named, unitsStyle: .wide))
    }
}
