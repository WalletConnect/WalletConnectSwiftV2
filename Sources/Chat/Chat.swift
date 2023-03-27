import Foundation

/// Chat instatnce wrapper
public class Chat {

    /// Chat client instance
    public static var instance: ChatClient = {
        guard let keyserverUrl = keyserverUrl else {
            fatalError("Error - you must call Chat.configure(_:) before accessing the shared instance.")
        }
        return ChatClientFactory.create(
            keyserverUrl: keyserverUrl,
            relayClient: Relay.instance,
            networkingInteractor: Networking.interactor
        )
    }()

    private static var keyserverUrl: String?

    private init() { }

    /// Chat instance config method
    /// - Parameters:
    ///   - account: Chat initial account
    static public func configure(keyserverUrl: String = "https://keys.walletconnect.com") {
        Chat.keyserverUrl = keyserverUrl
    }
}
