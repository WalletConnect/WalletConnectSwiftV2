import Foundation
import WalletConnectRelay
import Combine

public class Auth {

    public static var instance: AuthClient = {
        guard let config = Auth.config else {
            fatalError("Error - you must call Auth.configure(_:) before accessing the shared instance.")
        }
        return AuthClientFactory.create(
            metadata: config.metadata,
            account: config.account,
            relayClient: Relay.instance)
    }()
    
    private static var config: Config?

    private init() { }

    static public func configure(metadata: AppMetadata, account: Account?) {
        Auth.config = Auth.Config(
            metadata: metadata,
            account: account)
    }
}
