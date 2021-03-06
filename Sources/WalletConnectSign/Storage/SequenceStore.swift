import Foundation
import WalletConnectUtils

protocol Expirable {
    var expiryDate: Date { get }
}

protocol Entitled {
    var topic: String { get }
}

typealias SequenceObject = Entitled & Expirable & Codable

final class SequenceStore<T> where T: SequenceObject {

    var onSequenceExpiration: ((_ sequence: T) -> Void)?

    private let store: CodableStore<T>
    private let dateInitializer: () -> Date

    init(store: CodableStore<T>, dateInitializer: @escaping () -> Date = Date.init) {
        self.store = store
        self.dateInitializer = dateInitializer
    }

    func hasSequence(forTopic topic: String) -> Bool {
        (try? getSequence(forTopic: topic)) != nil
    }

    func setSequence(_ sequence: T) {
        store.set(sequence, forKey: sequence.topic)
    }

    func getSequence(forTopic topic: String) throws -> T? {
        guard let value = try store.get(key: topic) else { return nil }
        return verifyExpiry(on: value)
    }

    func getAll() -> [T] {
        let values = store.getAll()
        return values.compactMap { verifyExpiry(on: $0) }
    }

    func delete(topic: String) {
        store.delete(forKey: topic)
    }

    func deleteAll() {
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
