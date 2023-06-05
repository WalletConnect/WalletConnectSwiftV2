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
            derivator: config.derivator
        )
    }()

    private static var config: Config?

    private init() { }

    /// Auth instance wallet config method.  For DApp usage
    /// - Parameters:
    ///   - crypto: Crypto utils implementation
    static public func configure(derivator: DerivationProvider) {
        Sync.config = Sync.Config(derivator: derivator)
    }
}
