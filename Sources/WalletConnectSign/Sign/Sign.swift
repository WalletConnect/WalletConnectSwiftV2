import Foundation
import Combine

#if SWIFT_PACKAGE
public typealias VerifyContext = WalletConnectVerify.VerifyContext
#endif

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
        return SignClientFactory.create(
            metadata: Pair.metadata,
            pairingClient: Pair.instance as! PairingClient,
            networkingClient: Networking.instance as! NetworkingInteractor,
            groupIdentifier: Networking.groupIdentifier
        )
    }()

    private init() { }
}
