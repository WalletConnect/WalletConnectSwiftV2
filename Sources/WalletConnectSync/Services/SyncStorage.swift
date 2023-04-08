import Foundation
import Combine

final class SyncStorage {

    private var syncUpdateSubject = PassthroughSubject<SyncUpdate, Never>()

    var syncUpdatePublisher: AnyPublisher<SyncUpdate, Never> {
        syncUpdateSubject.eraseToAnyPublisher()
    }

    private let keychain: KeychainStorageProtocol
    private let database: KeyedDatabase<SyncRecord>

    init(keychain: KeychainStorageProtocol, database: KeyedDatabase<SyncRecord>) {
        self.keychain = keychain
        self.database = database
    }

    func saveIdentityKey(_ key: String, for account: Account) throws {
        try keychain.add(key, forKey: signatureIdentifier(for: account))
    }

    func getSignature(for account: Account) throws -> String {
        let identifier = signatureIdentifier(for: account)

        guard let key: String = try? keychain.read(key: identifier)
        else { throw Errors.signatureNotFound }

        return key
    }

    func set(update: StoreUpdate, topic: String, store: String, for account: Account) {
        let record = SyncRecord(topic: topic, store: store, update: update)
        database.set(record, for: account.absoluteString)
        syncUpdateSubject.send(record.publicRepresentation())
    }
}

private extension SyncStorage {

    enum Errors: Error {
        case signatureNotFound
    }

    func signatureIdentifier(for account: Account) -> String {
        return "com.walletconnect.sync.signature.\(account.absoluteString)"
    }
}
