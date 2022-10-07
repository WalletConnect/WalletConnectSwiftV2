import Foundation

final class AppUpdateMetadataService {

    private let pairingStore: WCPairingStorage

    init(pairingStore: WCPairingStorage) {
        self.pairingStore = pairingStore
    }

    func updatePairingMetadata(topic: String, metadata: AppMetadata) {
        guard var pairing = pairingStore.getPairing(forTopic: topic) else { return }
        pairing.peerMetadata = metadata
        pairingStore.setPairing(pairing)
    }
}
