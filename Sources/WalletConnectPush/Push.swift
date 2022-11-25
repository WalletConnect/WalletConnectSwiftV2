import Foundation
import WalletConnectNetworking
import WalletConnectPairing

public class Push {

    /// Auth client instance
    public static var instance: PushClient = {
        return PushClientFactory.create(
            metadata: Pair.metadata,
            networkInteractor: Networking.interactor,
            pairingRegisterer: Pair.registerer
        )
    }()

    private init() { }
}
