import Foundation

protocol Expirable {
    var expiryDate: Date { get }
}

protocol ExpirableSequence: Codable, Expirable {
    var topic: String { get }
}

final class SequenceStore<T> where T: ExpirableSequence {

    var onSequenceExpiration: ((String) -> Void)?
    
    private let storage: KeyValueStorage
    private let dateInitializer: () -> Date
    private let identifier: String

    init(storage: KeyValueStorage, uniqueIdentifier: String? = nil, dateInitializer: @escaping () -> Date = Date.init) {
        self.storage = storage
        self.dateInitializer = dateInitializer
        self.identifier = "com.walletconnect.sdk.\(uniqueIdentifier ?? "")"
    }
    
    func hasSequence(forTopic topic: String) -> Bool {
        (try? getSequence(forTopic: topic)) != nil
    }

    func setSequence(_ sequence: T) throws {
        let encoded = try JSONEncoder().encode(sequence)
        storage.set(encoded, forKey: getKey(for: sequence.topic))
    }

    func getSequence(forTopic topic: String) throws -> T? {
        guard let data = storage.object(forKey: getKey(for: topic)) as? Data else { return nil }
        let sequence = try JSONDecoder().decode(T.self, from: data)
        return verifyExpiry(on: sequence)
    }

    func getAll() -> [T] {
        return storage.dictionaryRepresentation().compactMap {
            if let data = $0.value as? Data, let sequence = try? JSONDecoder().decode(T.self, from: data) {
                return verifyExpiry(on: sequence)
            }
            return nil
        }
    }

    func update(sequence: T) throws {
        storage.removeObject(forKey: getKey(for: sequence.topic))
        try setSequence(sequence)
    }
    
    //TODO - to be removed after session engine refactor
    func update(sequence: T, onTopic topic: String) throws {
        storage.removeObject(forKey: getKey(for: topic))
        try setSequence(sequence)
    }
    func delete(topic: String) {
        storage.removeObject(forKey: getKey(for: topic))
    }
    
    private func verifyExpiry(on sequence: T) -> T? {
        let now = dateInitializer()
        if now >= sequence.expiryDate {
            storage.removeObject(forKey: getKey(for: sequence.topic))
            onSequenceExpiration?(sequence.topic)
            return nil
        }
        return sequence
    }
    
    private func getKey(for topic: String) -> String {
        return "\(identifier).\(topic)"
    }
}
