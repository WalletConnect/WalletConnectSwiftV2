import Foundation

public final class SyncStoreFactory {

    public static func create<Object: DatabaseObject>(name: String, syncClient: SyncClient, storage: KeyValueStorage) -> SyncStore<Object> {
        let indexDatabase = CodableStore<SyncRecord>(defaults: UserDefaults.standard, identifier: SyncStorageIdentifiers.index.identifier)
        let indexStore = SyncIndexStore(store: indexDatabase)
        let objectIdentifier = SyncStorageIdentifiers.object(store: name).identifier
        let objectStore = KeyedDatabase<Object>(storage: storage, identifier: objectIdentifier)
        return SyncStore(name: name, syncClient: syncClient, indexStore: indexStore, objectStore: objectStore)
    }
}
