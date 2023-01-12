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
        Echo.configure(clientId: config.clientId)
        return WalletPushClientFactory.create(
            networkInteractor: Networking.interactor,
            pairingRegisterer: Pair.registerer,
            echoClient: Echo.instance
        )
    }()

    private static var config: Config?

    private init() { }

    // Wallet's configure method
    static public func configure(clientId: String) {
        Push.config = Push.Config(clientId: clientId)
    }

}
