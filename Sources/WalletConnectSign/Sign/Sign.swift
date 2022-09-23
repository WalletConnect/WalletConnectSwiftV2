import Foundation
import WalletConnectUtils
import WalletConnectRelay
import Combine

public typealias Account = WalletConnectUtils.Account
public typealias Blockchain = WalletConnectUtils.Blockchain

/// Sign instatnce wrapper
///
/// ```swift
/// let metadata = AppMetadata(
///         name: "Swift wallet",
///         description: "wallet",
///         url: "wallet.connect",
///         icons:  ["https://my_icon.com/1"])
/// Sign.configure(metadata: metadata)
/// try await Sign.instance.pair(uri: uri)
/// ```
public class Sign {

    /// Sign client instance
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

    /// Sign instance config method
    /// - Parameters:
    ///   - metadata: App metadata
    static public func configure(metadata: AppMetadata) {
        Sign.metadata = metadata
    }
}
