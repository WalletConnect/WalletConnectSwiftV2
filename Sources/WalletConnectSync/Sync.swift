import Foundation

/// Sync instatnce wrapper
public class Sync {

    /// Sync client instance
    public static var instance: SyncClient = {
        guard let config = config else {
            fatalError("Error - you must call Sync.configure(_:) before accessing the shared instance.")
        }
        return SyncClientFactory.create(
            networkInteractor: Networking.interactor,
            bip44: config.bip44
        )
    }()

    private static var config: Config?

    private init() { }

    /// Auth instance wallet config method.  For DApp usage
    /// - Parameters:
    ///   - crypto: Crypto utils implementation
    static public func configure(bip44: BIP44Provider) {
        Sync.config = Sync.Config(bip44: bip44)
    }
}
