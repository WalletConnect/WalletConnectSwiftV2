import Foundation

// TODO: After Chat SDK integration
struct Message: Codable, Equatable {
    let message: String
    let authorAccount: String
    let timestamp: Int64
}

struct MessageViewModel {
    private let message: Message
    private let currentAccount: String

    init(message: Message, currentAccount: String) {
        self.message = message
        self.currentAccount = currentAccount
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
