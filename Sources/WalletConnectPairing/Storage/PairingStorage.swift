import Foundation

public protocol WCPairingStorage: AnyObject {
    var onPairingExpiration: ((WCPairing) -> Void)? { get set }
    func hasPairing(forTopic topic: String) -> Bool
    func setPairing(_ pairing: WCPairing)
    func getPairing(forTopic topic: String) -> WCPairing?
    func getAll() -> [WCPairing]
    func delete(topic: String)
    func deleteAll()
}

public final class PairingStorage: WCPairingStorage {

    public var onPairingExpiration: ((WCPairing) -> Void)? {
        get { storage.onSequenceExpiration }
        set { storage.onSequenceExpiration = newValue }
    }

    private let storage: SequenceStore<WCPairing>

    public init(storage: SequenceStore<WCPairing>) {
        self.storage = storage
    }

    public func hasPairing(forTopic topic: String) -> Bool {
        storage.hasSequence(forTopic: topic)
    }

    public func setPairing(_ pairing: WCPairing) {
        storage.setSequence(pairing)
    }

    public func getPairing(forTopic topic: String) -> WCPairing? {
        try? storage.getSequence(forTopic: topic)
    }

    public func getAll() -> [WCPairing] {
        storage.getAll()
    }

    public func delete(topic: String) {
        storage.delete(topic: topic)
    }

    public func deleteAll() {
        storage.deleteAll()
    }
}
