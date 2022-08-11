import WalletConnectPairing
@testable import WalletConnectSign

final class WCPairingStorageMock: WCPairingStorage {

    var onPairingExpiration: ((WCPairing) -> Void)?

    private(set) var pairings: [String: WCPairing] = [:]

    func hasPairing(forTopic topic: String) -> Bool {
        pairings[topic] != nil
    }

    func setPairing(_ pairing: WCPairing) {
        pairings[pairing.topic] = pairing
    }

    func getPairing(forTopic topic: String) -> WCPairing? {
        pairings[topic]
    }

    func getAll() -> [WCPairing] {
        Array(pairings.values)
    }

    func delete(topic: String) {
        pairings[topic] = nil
    }

    func deleteAll() {
        pairings = [:]
    }
}
