import Foundation

protocol Expirable {
    var expiryDate: Date { get }
}

protocol WCSequence: Codable, Expirable {
    var topic: String { get }
}

final class SequenceStore<T> where T: WCSequence {

    var onSequenceExpiration: ((String) -> Void)?
    
    private let storage: KeyValueStorage
    private let dateInitializer: () -> Date

    init(storage: KeyValueStorage, dateInitializer: @escaping () -> Date = Date.init) {
        self.storage = storage
        self.dateInitializer = dateInitializer
    }

    func setSequence(_ sequence: T) throws {
        let encoded = try JSONEncoder().encode(sequence)
        storage.set(encoded, forKey: sequence.topic)
    }

    func getSequence(forTopic topic: String) throws -> T? {
        guard let data = storage.object(forKey: topic) as? Data else { return nil }
        let sequence = try JSONDecoder().decode(T.self, from: data)

        let now = dateInitializer()
        if now >= sequence.expiryDate {
            storage.removeObject(forKey: topic)
            onSequenceExpiration?(topic)
            return nil
        }
        return sequence
    }

    func getAll() -> [T] {
        return storage.dictionaryRepresentation().compactMap {
            if let data = $0.value as? Data, let sequence = try? JSONDecoder().decode(T.self, from: data) {

                let now = dateInitializer()
                if now >= sequence.expiryDate {
                    storage.removeObject(forKey: $0.key)
                    onSequenceExpiration?($0.key)
                    return nil
                }
                return sequence
            }
            return nil
        }
    }

    func update(sequence: T, onTopic topic: String) throws {
        storage.removeObject(forKey: topic)
        try setSequence(sequence)
    }

    func delete(forTopic topic: String) {
        storage.removeObject(forKey: topic)
    }
}
