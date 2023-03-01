import Foundation
import WalletConnectChat

struct MessageViewModel: Identifiable {
    private let message: Message
    private let thread: WalletConnectChat.Thread

    var id: UInt64 {
        return message.timestamp
    }

    init(message: Message, thread: WalletConnectChat.Thread) {
        self.message = message
        self.thread = thread
    }

    var currentAccount: Account {
        return thread.selfAccount
    }

    var isCurrentUser: Bool {
        return currentAccount == message.authorAccount
    }

    var text: String {
        return message.message
    }

    var showAvatar: Bool {
        return !isCurrentUser
    }
}
