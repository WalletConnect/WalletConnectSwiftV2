import Foundation
import Combine

#if SWIFT_PACKAGE
public typealias VerifyContext = WalletConnectVerify.VerifyContext
#endif

/// Auth instatnce wrapper
///
/// ```Swift
/// let metadata = AppMetadata(
///         name: "Swift wallet",
///         description: "wallet",
///         url: "wallet.connect",
///         icons:  ["https://my_icon.com/1"])
/// Auth.configure(metadata: metadata, account: account)
/// try await Auth.instance.pair(uri: uri)
/// ```
public class Auth {

    /// Auth client instance
    public static var instance: AuthClient = {
        guard let config = Auth.config else {
            fatalError("Error - you must call Auth.configure(_:) before accessing the shared instance.")
        }
        return AuthClientFactory.create(
            metadata: Pair.metadata,
            projectId: Networking.projectId,
            crypto: config.crypto,
            networkingClient: Networking.interactor,
            pairingRegisterer: Pair.registerer
        )
    }()

    private static var config: Config?

    private init() { }

    /// Auth instance wallet config method.  For DApp usage
    /// - Parameters:
    ///   - signerFactory: Auth signers factory
    static public func configure(crypto: CryptoProvider) {
        Auth.config = Auth.Config(crypto: crypto)
    }
}
