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
    
    private let storage: KeyValueStorage
    private let dateInitializer: () -> Date
    private let identifier: String

    init(storage: KeyValueStorage, identifier: String, dateInitializer: @escaping () -> Date = Date.init) {
        self.storage = storage
        self.dateInitializer = dateInitializer
        self.identifier = identifier
    }
    
    func hasSequence(forTopic topic: String) -> Bool {
        (try? getSequence(forTopic: topic)) != nil
    }
    
    //  This force-unwrap is safe because Expirable Sequances are JSON Encodable
    func setSequence(_ sequence: T) {
        let encoded = try! JSONEncoder().encode(sequence)
        storage.set(encoded, forKey: getKey(for: sequence.topic))
    }

    func getSequence(forTopic topic: String) throws -> T? {
        guard let data = storage.object(forKey: getKey(for: topic)) as? Data else { return nil }
        let sequence = try JSONDecoder().decode(T.self, from: data)
        return verifyExpiry(on: sequence)
    }

    func getAll() -> [T] {
        return dictionaryForIdentifier().compactMap {
            if let data = $0.value as? Data, let sequence = try? JSONDecoder().decode(T.self, from: data) {
                return verifyExpiry(on: sequence)
            }
            return nil
        }
    }

    func delete(topic: String) {
        storage.removeObject(forKey: getKey(for: topic))
    }
    
    func deleteAll() {
        dictionaryForIdentifier()
            .forEach { storage.removeObject(forKey: $0.key) }
    }
    
    private func verifyExpiry(on sequence: T) -> T? {
        let now = dateInitializer()
        if now >= sequence.expiryDate {
            storage.removeObject(forKey: getKey(for: sequence.topic))
            onSequenceExpiration?(sequence)
            return nil
        }
        return sequence
    }
    
    private func getKey(for topic: String) -> String {
        return "\(identifier).\(topic)"
    }
    
    private func dictionaryForIdentifier() -> [String : Any] {
        return storage.dictionaryRepresentation()
            .filter { $0.key.hasPrefix("\(identifier).") }
    }
}
