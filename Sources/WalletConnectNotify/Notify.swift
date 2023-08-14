import Foundation

public class Notify {
    public static var wallet: NotifyClient = {
        guard let config = Notify.config else {
            fatalError("Error - you must call Notify.configure(_:) before accessing the shared wallet instance.")
        }
        Push.configure(pushHost: config.pushHost, environment: config.environment)
        return NotifyClientFactory.create(
            networkInteractor: Networking.interactor,
            pairingRegisterer: Pair.registerer,
            pushClient: Push.instance,
            syncClient: Sync.instance,
            historyClient: History.instance,
            crypto: config.crypto
        )
    }()

    private static var config: Config?

    private init() { }

    /// Wallet's configuration method
    static public func configure(pushHost: String = "echo.walletconnect.com", environment: APNSEnvironment, crypto: CryptoProvider) {
        Notify.config = Notify.Config(pushHost: pushHost, environment: environment, crypto: crypto)
    }

}
