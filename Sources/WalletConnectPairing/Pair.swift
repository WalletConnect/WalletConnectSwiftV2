import Foundation
import WalletConnectNetworking
import Combine

public class Pair {

    /// Pairing client instance
    public static var instance: PairingInteracting = {
        guard let config = Pair.config else {
            fatalError("Error - you must call Pair.configure(_:) before accessing the shared instance.")
        }
        return PairingClientFactory.create(networkingClient: Networking.instance as! NetworkingInteractor)
    }()

    public static var metadata: AppMetadata {
        guard let metadata = config?.metadata else {
            fatalError("Error - you must configure metadata with Pair.configure(metadata:)")
        }
        return metadata
    }

    private static var config: Config?

    private init() { }

    /// Pairing instance config method
    /// - Parameters:
    ///   - metadata: App metadata
    static public func configure(metadata: AppMetadata) {
        Pair.config = Pair.Config(metadata: metadata)
    }
}
