import Foundation
import Combine

public enum SyncUpdate<Object: DatabaseObject> {
    case set(object: Object)
    case delete(object: Object)
    case update(object: Object)
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

    public func create(for account: Account) async throws {
        try await syncClient.create(account: account, store: name)
    }

    public func subscribe(for account: Account) async throws {
        try await syncClient.subscribe(account: account, store: name)
    }

    public func setupDatabaseSubscriptions(account: Account) throws {
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

    public func get(for id: String) -> Object? {
        return getAll().first(where: { $0.databaseId == id })
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

    public func delete(id: String) async throws {
        guard let result = objectStore.find(id: id) else {
            return
        }
        let record = try indexStore.getRecord(topic: result.key)
        try await delete(id: id, for: record.account)
    }

    public func getStoreTopic(account: Account) throws -> String {
        let record = try indexStore.getRecord(account: account, name: name)
        return record.topic
    }

    public func replaceInStore(objects: [Object], for account: Account) throws {
        let record = try indexStore.getRecord(account: account, name: name)
        objectStore.deleteAll(for: record.topic)
        objectStore.set(elements: objects, for: record.topic)
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
                let exists = objectStore.exists(for: record.topic, id: object.databaseId)
                if try! setInStore(object: object, for: record.account) {
                    let update: SyncUpdate = exists ? .update(object: object) : .set(object: object)
                    syncUpdateSubject.send((topic, record.account, update))
                }
            case .delete(let delete):
                if let object = get(for: delete.key), try! deleteInStore(id: delete.key, for: record.account) {
                    syncUpdateSubject.send((topic, record.account, .delete(object: object)))
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
