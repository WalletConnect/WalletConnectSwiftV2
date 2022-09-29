import Foundation
import WalletConnectRelay
import Combine

extension Pair {
    struct Config {
        let metadata: AppMetadata
    }
}

public class Pair {

    /// Pairing client instance
    public static var instance: PairingClient = {
        guard let config = Pair.config else {
            fatalError("Error - you must call Pair.configure(_:) before accessing the shared instance.")
        }
        return PairingClientFactory.create(relayClient: Relay.instance)
    }()

    private static var config: Config?

    private init() { }

    /// Pairing instance config method
    /// - Parameters:
    ///   - metadata: App metadata
    static public func configure(metadata: AppMetadata) {
        Pair.config = Pair.Config(metadata: metadata)
    }
}
