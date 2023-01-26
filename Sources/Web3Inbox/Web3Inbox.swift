import Foundation

public final class Web3Inbox {

    /// Web3Inbox client instance
    public static var instance: Web3InboxClient = {
        guard let account = account else {
            fatalError("Error - you must call Web3Inbox.configure(_:) before accessing the shared instance.")
        }
        return Web3InboxClientFactory.create(chatClient: Chat.instance, account: account)
    }()

    private static var account: Account?

    private init() { }

    /// Web3Inbox instance config method
    /// - Parameters:
    ///   - account: Web3Inbox initial account
    static public func configure(account: Account) {
        Chat.configure(account: account)
        Web3Inbox.account = account
    }
}
