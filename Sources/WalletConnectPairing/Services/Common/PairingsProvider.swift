import Foundation

class PairingsProvider {
    enum Errors: Error {
        case noPairingMatchingTopic
    }
    private let pairingStorage: WCPairingStorage

    public init(pairingStorage: WCPairingStorage) {
        self.pairingStorage = pairingStorage
    }

    func getPairings() -> [Pairing] {
        pairingStorage.getAll()
            .map {Pairing($0)}
    }

    func getPairing(for topic: String) throws -> Pairing {
        guard let pairing = pairingStorage.getPairing(forTopic: topic) else {
            throw Errors.noPairingMatchingTopic
        }
        return Pairing(pairing)
    }
}
