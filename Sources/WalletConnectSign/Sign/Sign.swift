import Foundation
import WalletConnectUtils
import WalletConnectRelay
import Combine

public typealias Account = WalletConnectUtils.Account
public typealias Blockchain = WalletConnectUtils.Blockchain

public class Sign {

    public static var instance: SignClient = {
        guard let metadata = Sign.metadata else {
            fatalError("Error - you must call Sign.configure(_:) before accessing the shared instance.")
        }
        return SignClientFactory.create(
            metadata: metadata,
            relayClient: Relay.instance
        )
    }()

    private static var metadata: AppMetadata?

    private init() { }

    static public func configure(metadata: AppMetadata) {
        Sign.metadata = metadata
    }
}
