import Foundation

public final class Web3Inbox {

    /// Web3Inbox client instance
    public static var instance: Web3InboxClient = {
        guard let account, let config = config, let onSign else {
            fatalError("Error - you must call Web3Inbox.configure(_:) before accessing the shared instance.")
        }
        return Web3InboxClientFactory.create(chatClient: Chat.instance, notifyClient: Notify.instance, account: account, config: config, onSign: onSign)
    }()

    private static var account: Account?
    private static var config: [ConfigParam: Bool]?
    private static var onSign: SigningCallback?

    private init() { }

    /// Web3Inbox instance config method
    static public func configure(
        account: Account,
        bip44: BIP44Provider,
        config: [ConfigParam: Bool] = [:],
        groupIdentifier: String,
        environment: APNSEnvironment,
        crypto: CryptoProvider,
        onSign: @escaping SigningCallback
    ) {
        Web3Inbox.account = account
        Web3Inbox.config = config
        Web3Inbox.onSign = onSign
        Chat.configure(bip44: bip44)
        Notify.configure(groupIdentifier: groupIdentifier, environment: environment, crypto: crypto)
    }
}
