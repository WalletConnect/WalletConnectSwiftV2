import Foundation
import Combine

#if SWIFT_PACKAGE
public typealias VerifyContext = WalletConnectVerify.VerifyContext
#endif

/// Web3Wallet instance wrapper
///
/// ```Swift
/// let metadata = AppMetadata(
///     name: "Swift wallet",
///     description: "wallet",
///     url: "wallet.connect",
///     icons:  ["https://my_icon.com/1"]
/// )
/// Web3Wallet.configure(metadata: metadata, account: account)
/// Web3Wallet.instance.getSessions()
/// ```
///
/// - Warning: `Web3Wallet` has been deprecated. Please migrate to `WalletKit` which can be found at [https://github.com/reown-com/reown-swift](https://github.com/reown-com/reown-swift).
@available(*, deprecated, message: "WalletConnect Inc is now Reown. As part of this transition, we are deprecating a number of repositories/packages across our supported platforms, and transitioning to their equivalents published under the Reown organization. This repository is now considered deprecated and will reach End-of-Life on February 17th 2025. For more details, including migration guides please see: https://docs.reown.com/advanced/walletconnect-deprecations")
public class Web3Wallet {

    /// Web3Wallet client instance
    public static var instance: Web3WalletClient = {
        guard let config = Web3Wallet.config else {
            fatalError("Error - you must call Web3Wallet.configure(_:) before accessing the shared instance.")
        }
        return Web3WalletClientFactory.create(
            signClient: Sign.instance,
            pairingClient: Pair.instance as! PairingClient,
            pushClient: Push.instance
        )
    }()

    private static var config: Config?

    private init() { }

    /// Wallet instance wallet config method.
    /// - Parameters:
    ///   - metadata: App metadata
    ///   - crypto: Auth crypto utils
    @available(*, deprecated, message: "Web3Wallet.configure has been deprecated. Please migrate to WalletKit.configure.")
    static public func configure(
        metadata: AppMetadata,
        crypto: CryptoProvider,
        pushHost: String = "echo.walletconnect.com",
        environment: APNSEnvironment = .production
    ) {
        Pair.configure(metadata: metadata)
        Push.configure(pushHost: pushHost, environment: environment)
        Sign.configure(crypto: crypto)
        Web3Wallet.config = Web3Wallet.Config(crypto: crypto)
    }
}
