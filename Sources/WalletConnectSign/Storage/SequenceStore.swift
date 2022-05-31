import Foundation
import WalletConnectUtils

protocol Expirable {
    var expiryDate: Date { get }
}

protocol ExpirableSequence: Codable, Expirable {
    var topic: String { get }
}

// TODO: Find replacement for 'Sequence' prefix
final class SequenceStore<T> where T: ExpirableSequence {

    var onSequenceExpiration: ((_ sequence: T) -> Void)?
    
    private let store: KeyValueStore<T>
    private let dateInitializer: () -> Date

    init(store: KeyValueStore<T>, dateInitializer: @escaping () -> Date = Date.init) {
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
    
    private func verifyExpiry(on sequence: T) -> T? {
        let now = dateInitializer()
        if now >= sequence.expiryDate {
            store.delete(forKey: sequence.topic)
            onSequenceExpiration?(sequence)
            return nil
        }
        return sequence
    }
}
