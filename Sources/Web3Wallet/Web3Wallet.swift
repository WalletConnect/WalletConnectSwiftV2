import Foundation
import Combine

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
public class Web3Wallet {
    /// Web3Wallett client instance
    public static var instance: Web3WalletClient = {
        guard let config = Web3Wallet.config else {
            fatalError("Error - you must call Web3Wallet.configure(_:) before accessing the shared instance.")
        }
        
        return Web3WalletClientFactory.create(
            authClient: Auth.instance,
            signClient: Sign.instance,
            pairingClient: Pair.instance as! PairingClient
        )
    }()
    
    private static var config: Config?

    private init() { }

    /// Wallet instance wallet config method.
    /// - Parameters:
    ///   - metadata: App metadata
    ///   - signerFactory: Auth signers factory
    static public func configure(metadata: AppMetadata, signerFactory: SignerFactory) {
        Pair.configure(metadata: metadata)
        Auth.configure(signerFactory: signerFactory)
        
        Web3Wallet.config = Web3Wallet.Config(signerFactory: signerFactory)
    }
}
