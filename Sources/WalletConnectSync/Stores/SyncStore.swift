import Foundation
import Combine

public enum SyncUpdate<Object: DatabaseObject> {
    case set(object: Object)
    case delete(id: String)
}

public final class SyncStore<Object: DatabaseObject> {

    private var publishers = Set<AnyCancellable>()

    private let name: String
    private let syncClient: SyncClient

    /// `account` to `Record` keyValue store
    private let indexStore: SyncIndexStore

    /// `storeTopic` to [`id`: `Object`] map keyValue store
    private let objectStore: KeyedDatabase<Object>

    private let dataUpdateSubject = PassthroughSubject<[Object], Never>()
    private let syncUpdateSubject = PassthroughSubject<(String, Account, SyncUpdate<Object>), Never>()

    public var dataUpdatePublisher: AnyPublisher<[Object], Never> {
        return dataUpdateSubject.eraseToAnyPublisher()
    }

    public var syncUpdatePublisher: AnyPublisher<(String, Account, SyncUpdate<Object>), Never> {
        return syncUpdateSubject.eraseToAnyPublisher()
    }

    init(name: String, syncClient: SyncClient, indexStore: SyncIndexStore, objectStore: KeyedDatabase<Object>) {
        self.name = name
        self.syncClient = syncClient
        self.indexStore = indexStore
        self.objectStore = objectStore

        setupSubscriptions()
    }

    public func initialize(for account: Account) async throws {
        try await syncClient.create(account: account, store: name)
    }

    public func setupSubscriptions(account: Account) throws {
        let record = try indexStore.getRecord(account: account, name: name)

        objectStore.onUpdate = { [unowned self] in
            dataUpdateSubject.send(objectStore.getAll(for: record.topic))
        }
    }

    public func getAll(for account: Account) throws -> [Object] {
        let record = try indexStore.getRecord(account: account, name: name)
        return objectStore.getAll(for: record.topic)
    }

    public func getAll() -> [Object] {
        return objectStore.getAll()
    }

    public func set(object: Object, for account: Account) async throws {
        let record = try indexStore.getRecord(account: account, name: name)

        if objectStore.set(element: object, for: record.topic) {
            try await syncClient.set(account: account, store: record.store, object: object)
        }
    }

    public func delete(id: String, for account: Account) async throws {
        let record = try indexStore.getRecord(account: account, name: name)

        if objectStore.delete(id: id, for: record.topic) {
            try await syncClient.delete(account: account, store: record.store, key: id)
        }
    }
}

private extension SyncStore {

    func setupSubscriptions() {
        syncClient.updatePublisher.sink { [unowned self] (topic, update) in

            let record = try! indexStore.getRecord(topic: topic)

            guard record.store == name else { return }

            switch update {
            case .set(let set):
                let object = try! JSONDecoder().decode(Object.self, from: Data(set.value.utf8))
                if try! setInStore(object: object, for: record.account) {
                    syncUpdateSubject.send((topic, record.account, .set(object: object)))
                }
            case .delete(let delete):
                if try! deleteInStore(id: delete.key, for: record.account) {
                    syncUpdateSubject.send((topic, record.account, .delete(id: delete.key)))
                }
            }
        }.store(in: &publishers)
    }

    func setInStore(object: Object, for account: Account) throws -> Bool {
        let record = try indexStore.getRecord(account: account, name: name)
        return objectStore.set(element: object, for: record.topic)
    }

    func deleteInStore(id: String, for account: Account) throws -> Bool {
        let record = try indexStore.getRecord(account: account, name: name)
        return objectStore.delete(id: id, for: record.topic)
    }
}
