import Foundation

public class Push {

    public static var dapp: DappPushClient = {
        return DappPushClientFactory.create(
            metadata: Pair.metadata,
            networkInteractor: Networking.interactor,
            syncClient: Sync.instance
        )
    }()

    public static var wallet: WalletPushClient = {
        guard let config = Push.config else {
            fatalError("Error - you must call Push.configure(_:) before accessing the shared wallet instance.")
        }
        Echo.configure(echoHost: config.echoHost, environment: config.environment)
        return WalletPushClientFactory.create(
            networkInteractor: Networking.interactor,
            pairingRegisterer: Pair.registerer,
            echoClient: Echo.instance,
            syncClient: Sync.instance
        )
    }()

    private static var config: Config?

    private init() { }

    /// Wallet's configuration method
    static public func configure(echoHost: String = "echo.walletconnect.com", environment: APNSEnvironment) {
        Push.config = Push.Config(echoHost: echoHost, environment: environment)
    }

}
