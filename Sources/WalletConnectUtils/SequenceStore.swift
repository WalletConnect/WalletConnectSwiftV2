import Foundation

public protocol SequenceObject: Codable {
    var expiryDate: Date { get }
    var topic: String { get }
}

public final class SequenceStore<T> where T: SequenceObject {

    public var onSequenceExpiration: ((_ sequence: T) -> Void)?

    private let store: CodableStore<T>
    private let dateInitializer: () -> Date

    public init(store: CodableStore<T>, dateInitializer: @escaping () -> Date = Date.init) {
        self.store = store
        self.dateInitializer = dateInitializer
    }

    public func hasSequence(forTopic topic: String) -> Bool {
        (try? getSequence(forTopic: topic)) != nil
    }

    public func setSequence(_ sequence: T) {
        store.set(sequence, forKey: sequence.topic)
    }

    public func getSequence(forTopic topic: String) throws -> T? {
        guard let value = try store.get(key: topic) else { return nil }
        return verifyExpiry(on: value)
    }

    public func getAll() -> [T] {
        let values = store.getAll()
        return values.compactMap { verifyExpiry(on: $0) }
    }

    public func delete(topic: String) {
        store.delete(forKey: topic)
    }

    public func deleteAll() {
        store.deleteAll()
    }
}

// MARK: Privates

private extension SequenceStore {

    func verifyExpiry(on sequence: T) -> T? {
        let now = dateInitializer()
        if now >= sequence.expiryDate {
            store.delete(forKey: sequence.topic)
            onSequenceExpiration?(sequence)
            return nil
        }
        return sequence
    }
}
