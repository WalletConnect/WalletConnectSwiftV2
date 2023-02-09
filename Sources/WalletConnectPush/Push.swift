import Foundation
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectEcho

public class Push {

    public static var dapp: DappPushClient = {
        return DappPushClientFactory.create(
            metadata: Pair.metadata,
            networkInteractor: Networking.interactor
        )
    }()

    public static var wallet: WalletPushClient = {
        guard let config = Push.config else {
            fatalError("Error - you must call Push.configure(_:) before accessing the shared wallet instance.")
        }
        Echo.configure(clientId: config.clientId, echoHost: config.echoHost, environment: config.environment)
        return WalletPushClientFactory.create(
            networkInteractor: Networking.interactor,
            pairingRegisterer: Pair.registerer,
            echoClient: Echo.instance
        )
    }()

    private static var config: Config?

    private init() { }

    /// Wallet's configuration method
    static public func configure(echoHost: String = "echo.walletconnect.com", environment: APNSEnvironment) {
        let clientId = try! Networking.interactor.getClientId()
        Push.config = Push.Config(clientId: clientId, echoHost: echoHost, environment: environment)
    }

}
