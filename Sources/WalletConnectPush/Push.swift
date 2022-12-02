import Foundation
import WalletConnectNetworking
import WalletConnectPairing

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
                pairingRegisterer: Pair.registerer
            )
        }()

        private init() { }
    }

    private init() { }
}
