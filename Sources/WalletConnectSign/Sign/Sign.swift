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
            metadata: Sign.metadata ?? Pair.metadata,
            pairingClient: Pair.instance as! PairingClient,
            networkingClient: Networking.instance as! NetworkingInteractor
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
        Pair.configure(metadata: metadata)
        Sign.metadata = metadata
    }
}
