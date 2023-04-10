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

    func isExists(topic: String, id: String) -> Bool {
        return store.getElement(for: topic)?[id] != nil
    }

    func set(object: Object, topic: String) {
        var map = getMap(topic: topic)
        map[object.syncId] = object
        store.set(element: map, for: topic)
    }

    func delete(id: String, topic: String) {
        var map = getMap(topic: topic)
        map[id] = nil
        store.set(element: map, for: topic)
    }
}
