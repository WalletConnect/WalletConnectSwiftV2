import Foundation

public final class Web3Inbox {

    /// Web3Inbox client instance
    public static var instance: Web3InboxClient = {
        guard let account, let config = config, let onSign else {
            fatalError("Error - you must call Web3Inbox.configure(_:) before accessing the shared instance.")
        }
        return Web3InboxClientFactory.create(chatClient: Chat.instance, pushClient: Push.wallet, account: account, config: config, onSign: onSign)
    }()

    private static var account: Account?
    private static var config: [ConfigParam: Bool]?
    private static var onSign: SigningCallback?

    private init() { }

    /// Web3Inbox instance config method
    /// - Parameters:
    ///   - account: Web3Inbox initial account
    ///   - crypto: Crypto utils implementation
    static public func configure(
        account: Account,
        crypto: CryptoProvider,
        config: [ConfigParam: Bool] = [:],
        environment: APNSEnvironment,
        onSign: @escaping SigningCallback,
    ) {
        Web3Inbox.account = account
        Web3Inbox.config = config
        Web3Inbox.onSign = onSign
        Chat.configure(crypto: crypto)
        Push.configure(environment: environment)
    }
}
