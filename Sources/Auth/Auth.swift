import Foundation
import WalletConnectNetworking
import WalletConnectPairing
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
        return AuthClientFactory.create(
            metadata: Pair.metadata,
            account: config?.account,
            projectId: Networking.projectId,
            networkingClient: Networking.interactor,
            pairingRegisterer: Pair.registerer
        )
    }()

    private static var config: Config?

    private init() { }

    /// Auth instance wallet config method
    /// - Parameters:
    ///   - account: account that wallet will be authenticating with.
    static public func configure(account: Account) {
        Auth.config = Auth.Config(account: account)
    }
}
