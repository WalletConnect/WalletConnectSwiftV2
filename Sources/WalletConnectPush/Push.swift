import Foundation
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectEcho

public class Push {
    enum Errors: Error {
        case failedToGetClientId
    }

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

    /// Wallet's configuration method
    static public func configure() {
        var clientId: String!
        try! Networking.interactor.getClientId()
        Push.config = Push.Config(clientId: clientId)
    }

}
