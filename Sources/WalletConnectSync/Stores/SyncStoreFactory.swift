import Foundation

public final class SyncStoreFactory {

    public static func create<Object: SyncObject>(name: String, syncClient: SyncClient) -> SyncStore<Object> {
        let indexDatabase = CodableStore<SyncRecord>(defaults: UserDefaults.standard, identifier: SyncStorageIdentifiers.index.rawValue)
        let indexStore = SyncIndexStore(store: indexDatabase)
        let objectDatabase = NewKeyedDatabase<[String: Object]>(storage: UserDefaults.standard, identifier: SyncStorageIdentifiers.object.rawValue)
        let objectStore = SyncObjectStore(store: objectDatabase)
        return SyncStore(name: name, syncClient: syncClient, indexStore: indexStore, objectStore: objectStore)
    }
}
