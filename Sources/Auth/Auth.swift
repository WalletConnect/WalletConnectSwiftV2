import Foundation
import WalletConnectUtils
import WalletConnectRelay
import Combine

public class Auth {

    public static var instance: AuthClient = {
        guard let metadata = Auth.metadata else {
            fatalError("Error - you must call Sign.configure(_:) before accessing the shared instance.")
        }
        return AuthClientFactory.create(
            metadata: metadata,
            account: account,
            relayClient: Relay.instance)
    }()

    private static var metadata: AppMetadata?
    private static var account: Account?

    private init() { }

    static public func configure(metadata: AppMetadata, account: Account?) {
        Auth.metadata = metadata
        Auth.account = account
    }
}
