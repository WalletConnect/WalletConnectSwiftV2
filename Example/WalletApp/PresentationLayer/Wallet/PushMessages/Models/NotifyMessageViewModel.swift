import Foundation
import WalletConnectNotify

struct NotifyMessageViewModel: Identifiable {

    let pushMessageRecord: NotifyMessageRecord

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
