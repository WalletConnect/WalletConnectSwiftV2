import Foundation

/// Chat instatnce wrapper
public class Chat {

    /// Chat client instance
    public static var instance: ChatClient = {
        guard let account = account else {
            fatalError("Error - you must call Chat.configure(_:) before accessing the shared instance.")
        }
        return ChatClientFactory.create(
            account: account,
            relayClient: Relay.instance,
            networkingInteractor: Networking.interactor
        )
    }()

    private static var account: Account?

    private init() { }

    /// Chat instance config method
    /// - Parameters:
    ///   - account: Chat initial account
    static public func configure(account: Account) {
        Chat.account = account
    }
}
