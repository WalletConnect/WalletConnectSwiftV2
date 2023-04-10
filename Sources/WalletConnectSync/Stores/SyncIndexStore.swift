import Foundation

final class SyncIndexStore {

    /// `account-store` to SyncRecord map keyValue store
    private let store: CodableStore<SyncRecord>

    init(store: CodableStore<SyncRecord>) {
        self.store = store
    }

    func getRecord(account: Account, name: String) throws -> SyncRecord {
        let identifier = identifier(account: account, name: name)
        guard let record = try store.get(key: identifier) else {
            throw Errors.recordNotFoundForAccount
        }
        return record
    }

    func getRecord(topic: String) throws -> SyncRecord {
        guard let record = store.getAll().first(where: { $0.topic == topic }) else {
            throw Errors.accountNotFoundForTopic
        }
        return record
    }

    func set(topic: String, name: String, account: Account) {
        let identifier = identifier(account: account, name: name)
        let record = SyncRecord(topic: topic, store: name, account: account)
        store.set(record, forKey: identifier)
    }
}

private extension SyncIndexStore {

    enum Errors: Error {
        case recordNotFoundForAccount
        case accountNotFoundForTopic
    }

    func identifier(account: Account, name: String) -> String {
        return "\(account.absoluteString)-\(name)"
    }
}
