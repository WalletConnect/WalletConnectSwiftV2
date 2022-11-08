import Foundation
import Combine

final class AppPairActivationService {
    private let pairingStorage: PairingStorage
    private let logger: ConsoleLogging

    init(pairingStorage: PairingStorage, logger: ConsoleLogging) {
        self.pairingStorage = pairingStorage
        self.logger = logger
    }

    func activate(for topic: String) {
        guard var pairing = pairingStorage.getPairing(forTopic: topic) else {
            return logger.error("Pairing not found for topic: \(topic)")
        }
        if !pairing.active {
            pairing.activate()
        } else {
            try? pairing.updateExpiry()
        }
        pairingStorage.setPairing(pairing)
    }
}
