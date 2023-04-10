import Foundation
import Combine

public protocol SyncObject: Codable & Equatable {
    var syncId: String { get }
}

public final class SyncStore<Object: SyncObject> {

    private var publishers = Set<AnyCancellable>()

    private let name: String
    private let syncClient: SyncClient

    /// `account` to `Record` keyValue store
    private let indexStore: SyncIndexStore

    /// `storeTopic` to [`id`: `Object`] map keyValue store
    private let objectStore: SyncObjectStore<Object>

    private let dataUpdateSubject = PassthroughSubject<[Object], Never>()
    private let syncUpdateSubject = PassthroughSubject<(String, StoreUpdate), Never>()

    public var dataUpdatePublisher: AnyPublisher<[Object], Never> {
        return dataUpdateSubject.eraseToAnyPublisher()
    }

    public var syncUpdatePublisher: AnyPublisher<(String, StoreUpdate), Never> {
        return syncUpdateSubject.eraseToAnyPublisher()
    }

    init(name: String, syncClient: SyncClient, indexStore: SyncIndexStore, objectStore: SyncObjectStore<Object>) {
        self.name = name
        self.syncClient = syncClient
        self.indexStore = indexStore
        self.objectStore = objectStore

        setupSubscriptions()
    }

    public func initialize(for account: Account) async throws {
        try await syncClient.create(account: account, store: name)
    }

    public func getAll(for account: Account) throws -> [Object] {
        let record = try indexStore.getRecord(account: account, name: name)
        return objectStore.getAll(topic: record.topic)
    }

    public func getAll() -> [Object] {
        return objectStore.getAll()
    }

    public func set(object: Object, for account: Account) async throws {
        let record = try indexStore.getRecord(account: account, name: name)

        guard !objectStore.isExists(topic: record.topic, id: object.syncId) else {
            return
        }

        try await syncClient.set(account: account, store: record.store, object: object)

        objectStore.set(object: object, topic: record.topic)
    }

    public func delete(id: String, for account: Account) async throws {
        let record = try indexStore.getRecord(account: account, name: name)

        guard objectStore.isExists(topic: record.topic, id: id) else {
            return
        }

        try await syncClient.delete(account: account, store: record.store, key: id)

        objectStore.delete(id: id, topic: record.topic)
    }

    public func setupSubscriptions(account: Account) throws {
        let record = try indexStore.getRecord(account: account, name: name)

        objectStore.onUpdate = { [unowned self] in
            dataUpdateSubject.send(objectStore.getAll(topic: record.topic))
        }
    }
}

private extension SyncStore {

    func setupSubscriptions() {
        syncClient.updatePublisher.sink { [unowned self] (topic, update) in

            let record = try! indexStore.getRecord(topic: topic)

            guard record.topic == name else { return }

            switch update {
            case .set(let value):
                let decoded = try! value.get(StoreSet<Object>.self)
                try! setInStore(object: decoded.value, for: record.account)
                syncUpdateSubject.send((topic, update))
            case .delete(let key):
                try! deleteInStore(id: key, for: record.account)
                syncUpdateSubject.send((topic, update))
            }
        }.store(in: &publishers)
    }

    func setInStore(object: Object, for account: Account) throws {
        let record = try indexStore.getRecord(account: account, name: name)

        guard !objectStore.isExists(topic: record.topic, id: object.syncId) else {
            return
        }

        objectStore.set(object: object, topic: record.topic)
    }

    func deleteInStore(id: String, for account: Account) throws {
        let record = try indexStore.getRecord(account: account, name: name)

        guard objectStore.isExists(topic: record.topic, id: id) else {
            return
        }

        objectStore.delete(id: id, topic: record.topic)
    }
}
