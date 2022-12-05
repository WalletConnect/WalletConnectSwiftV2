import Foundation
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectEcho

public class Push {

    class Dapp {
        public static var instance: DappPushClient = {
            return DappPushClientFactory.create(
                metadata: Pair.metadata,
                networkInteractor: Networking.interactor
            )
        }()

        private init() { }
    }

    class Wallet {
        public static var instance: WalletPushClient = {
            return WalletPushClientFactory.create(
                networkInteractor: Networking.interactor,
                pairingRegisterer: Pair.registerer,
                echoClient: Echo.instance
            )
        }()

        private init() { }
    }

    private init() { }
}
