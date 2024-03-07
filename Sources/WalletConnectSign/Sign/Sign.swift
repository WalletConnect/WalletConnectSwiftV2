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
        guard let config = Sign.config else {
            fatalError("Error - you must call Sign.configure(_:) before accessing the shared instance.")
        }
        return SignClientFactory.create(
            metadata: Pair.metadata,
            pairingClient: Pair.instance as! PairingClient,
            projectId: Networking.projectId,
            crypto: config.crypto,
            networkingClient: Networking.interactor,
            groupIdentifier: Networking.groupIdentifier

        )
    }()

    private static var config: Config?

    private init() { }

    /// Sign instance config method
    /// - Parameters:
    ///   - metadata: App metadata
    static public func configure(crypto: CryptoProvider) {
        Sign.config = Sign.Config(crypto: crypto)
    }
}

