import Foundation
import Combine

final class AppPairActivationService {
    enum Errors: Error {
        case pairingNotFound
    }

    private let pairingStorage: WCPairingStorage
    private let logger: ConsoleLogging

    init(pairingStorage: WCPairingStorage, logger: ConsoleLogging) {
        self.pairingStorage = pairingStorage
        self.logger = logger
    }

    func activate(for topic: String, peerMetadata: AppMetadata?) {
        guard var pairing = pairingStorage.getPairing(forTopic: topic) else {
            return logger.error("Pairing not found for topic: \(topic)")
        }

        if !pairing.active {
            pairing.activate()
        } else {
            try? pairing.updateExpiry()
        }

        pairing.updatePeerMetadata(peerMetadata)
        pairingStorage.setPairing(pairing)
    }
}
