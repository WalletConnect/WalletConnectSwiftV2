import Foundation

public final class Web3Inbox {

    /// Web3Inbox client instance
    public static var instance: Web3InboxClient = {
        return Web3InboxClientFactory.create(chatClient: Chat.instance)
    }()
}
