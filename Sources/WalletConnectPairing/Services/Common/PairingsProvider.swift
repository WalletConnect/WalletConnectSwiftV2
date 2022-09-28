import Foundation

public class PairingsProvider {
    private let pairingStorage: WCPairingStorage

    public init(pairingStorage: WCPairingStorage) {
        self.pairingStorage = pairingStorage
    }

    func getPairings() -> [Pairing] {
        pairingStorage.getAll()
            .map {Pairing(topic: $0.topic, peer: $0.peerMetadata, expiryDate: $0.expiryDate)}
    }
}
