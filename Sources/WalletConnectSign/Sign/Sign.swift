import Foundation
import Combine
import JSONRPC
import WalletConnectUtils
import WalletConnectRelay
import WalletConnectNetworking
import WalletConnectPairing

public typealias Account = WalletConnectUtils.Account
public typealias Blockchain = WalletConnectUtils.Blockchain
public typealias Reason = WalletConnectNetworking.Reason
public typealias RPCID = JSONRPC.RPCID

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
        guard let metadata = Sign.metadata ?? Pair.metadata else {
            fatalError("Error - you must call Sign.configure(_:) before accessing the shared instance.")
        }
        return SignClientFactory.create(
            metadata: metadata,
            relayClient: Relay.instance,
            pairingClient: Pair.instance
        )
    }()

    @available(*, deprecated, message: "Remove after clients migration")
    private static var metadata: AppMetadata?

    private init() { }

    /// Sign instance config method
    /// - Parameters:
    ///   - metadata: App metadata
    @available(*, deprecated, message: "Use Pair.configure(metadata:) instead")
    static public func configure(metadata: AppMetadata) {
        Sign.metadata = metadata
    }
}
