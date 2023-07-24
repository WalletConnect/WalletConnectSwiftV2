import Foundation

public class Notify {
    public static var wallet: WalletNotifyClient = {
        guard let config = Notify.config else {
            fatalError("Error - you must call Notify.configure(_:) before accessing the shared wallet instance.")
        }
        Echo.configure(echoHost: config.echoHost, environment: config.environment)
        return WalletNotifyClientFactory.create(
            networkInteractor: Networking.interactor,
            pairingRegisterer: Pair.registerer,
            echoClient: Echo.instance,
            syncClient: Sync.instance,
            historyClient: History.instance
        )
    }()

    private static var config: Config?

    private init() { }

    /// Wallet's configuration method
    static public func configure(echoHost: String = "echo.walletconnect.com", environment: APNSEnvironment) {
        Notify.config = Notify.Config(echoHost: echoHost, environment: environment)
    }

}
