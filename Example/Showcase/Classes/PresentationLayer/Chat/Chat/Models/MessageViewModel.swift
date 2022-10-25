import Foundation
import WalletConnectChat

struct MessageViewModel {
    private let message: Message
    private let thread: WalletConnectChat.Thread

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
