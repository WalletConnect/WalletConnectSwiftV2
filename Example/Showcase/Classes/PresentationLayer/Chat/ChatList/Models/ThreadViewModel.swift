import Foundation
import WalletConnectChat

struct ThreadViewModel: Identifiable {
    let thread: WalletConnectChat.Thread

    var topic: String {
        return thread.topic
    }

    var id: String {
        return thread.topic
    }

    var title: String {
        return AccountNameResolver.resolveName(thread.peerAccount)
    }

    var subtitle: String {
        return thread.topic
    }
}
