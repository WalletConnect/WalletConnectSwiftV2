import Foundation

final class SyncHistoryStore {

    /// `topic` to `rpcid` keyValue store
    private let store: CodableStore<Int64>

    init(store: CodableStore<Int64>) {
        self.store = store
    }

    func set(rpcid: Int64, topic: String) {
        store.set(rpcid, forKey: topic)
    }

    func update(topic: String, rpcid: RPCID) -> Bool {
        guard isNew(topic: topic, rpcid: rpcid) else { return false }
        store.set(rpcid.integer, forKey: topic)
        return true
    }
}

private extension SyncHistoryStore {

    func isNew(topic: String, rpcid: RPCID) -> Bool {
        guard let old = try? store.get(key: topic) else { return true }
        return old < rpcid.integer
    }
}
