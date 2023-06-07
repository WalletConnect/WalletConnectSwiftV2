import Foundation

final class SyncObjectStore<Object: SyncObject> {

    /// `storeTopic` to [`id`: `Object`] map keyValue store
    private let store: NewKeyedDatabase<[String: Object]>

    var onUpdate: (() -> Void)? {
        get {
            return store.onUpdate
        }
        set {
            store.onUpdate = newValue
        }
    }

    init(store: NewKeyedDatabase<[String : Object]>) {
        self.store = store
    }

    func getMap(topic: String) -> [String: Object] {
        return store.getElement(for: topic) ?? [:]
    }

    func getAll(topic: String) -> [Object] {
        let map = getMap(topic: topic)
        return Array(map.values)
    }

    func getAll() -> [Object] {
        return store.index.values.reduce([]) { result, values in
            return result + values.values
        }
    }

    @discardableResult func set(object: Object, topic: String) -> Bool {
        guard isChanged(object, topic: topic) else { return false }
        var map = getMap(topic: topic)
        map[object.syncId] = object
        store.set(element: map, for: topic)
        return true
    }


    @discardableResult func delete(id: String, topic: String) -> Bool {
        guard isExists(id: id, topic: topic) else { return false }
        var map = getMap(topic: topic)
        map[id] = nil
        store.set(element: map, for: topic)
        return true
    }
}

private extension SyncObjectStore {

    func isExists(id: String, topic: String) -> Bool {
        return getElement(id: id, topic: topic) != nil
    }

    func getElement(id: String, topic: String) -> Object? {
        return store.getElement(for: topic)?[id]
    }

    func isChanged(_ object: Object, topic: String) -> Bool {
        return object != getElement(id: object.syncId, topic: topic)
    }
}
