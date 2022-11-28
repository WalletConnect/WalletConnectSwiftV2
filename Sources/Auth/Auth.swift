import Foundation
import Combine

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
            account: config.account,
            projectId: Networking.projectId,
            signerFactory: config.signerFactory,
            networkingClient: Networking.interactor,
            pairingRegisterer: Pair.registerer
        )
    }()

    private static var config: Config?

    private init() { }

    /// Auth instance wallet config method. For Wallet usage
    /// - Parameters:
    ///   - account: account that wallet will be authenticating with.
    ///   - signerFactory: Multichain signers factory
    static public func configure(account: Account, signerFactory: SignerFactory) {
        Auth.config = Auth.Config(account: account, signerFactory: signerFactory)
    }

    /// Auth instance wallet config method.  For DApp usage
    /// - Parameters:
    ///   - signerFactory: Multichain signers factory
    static public func configure(signerFactory: SignerFactory) {
        Auth.config = Auth.Config(account: nil, signerFactory: signerFactory)
    }
}
