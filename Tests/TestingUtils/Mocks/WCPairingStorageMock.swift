import WalletConnectPairing

public final class WCPairingStorageMock: WCPairingStorage {

    public var onPairingExpiration: ((WCPairing) -> Void)?

    private(set) var pairings: [String: WCPairing] = [:]

    public func hasPairing(forTopic topic: String) -> Bool {
        pairings[topic] != nil
    }

    public func setPairing(_ pairing: WCPairing) {
        pairings[pairing.topic] = pairing
    }

    public func getPairing(forTopic topic: String) -> WCPairing? {
        pairings[topic]
    }

    public func getAll() -> [WCPairing] {
        Array(pairings.values)
    }

    public func delete(topic: String) {
        pairings[topic] = nil
    }

    public func deleteAll() {
        pairings = [:]
    }
}
