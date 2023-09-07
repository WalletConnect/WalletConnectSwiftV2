import Foundation
import Combine

public final class SyncClient {

    public var updatePublisher: AnyPublisher<(String, StoreUpdate), Never> {
        return syncService.updatePublisher
    }

    private let syncService: SyncService
    private let syncSignatureStore: SyncSignatureStore

    init(syncService: SyncService, syncSignatureStore: SyncSignatureStore) {
        self.syncService = syncService
        self.syncSignatureStore = syncSignatureStore
    }

    /// Get message to sign for an account
    public func getMessage(account: Account) -> String {
        return """
        I authorize this app to sync my account: \(account.absoluteString)

        Read more about it here: https://walletconnect.com/faq
        """
    }

    /// Checks if account is already registered in sync
    public func isRegistered(account: Account) -> Bool {
        return syncSignatureStore.isSignatureExists(account: account)
    }

    /// Register an account to sync
    public func register(account: Account, signature: CacaoSignature) async throws {
        // TODO: Signature verify
        try syncSignatureStore.saveSignature(signature.s, for: account)
    }

    /// Create a store
    public func create(account: Account, store: String) async throws {
        try await syncService.create(account: account, store: store)
    }

    /// Subscribe for sync topic
    public func subscribe(account: Account, store: String) async throws {
        try await syncService.subscribe(account: account, store: store)
    }

    // Set value to store
    public func set<Object: DatabaseObject>(
        account: Account,
        store: String,
        object: Object
    ) async throws {
        try await syncService.set(account: account, store: store, object: object)
    }

    // Set value from store by key
    public func delete(account: Account, store: String, key: String) async throws {
        try await syncService.delete(account: account, store: store, key: key)
    }

    // Get stores
    public func getStores(account: Account) -> StoreMap {
        fatalError()
    }
}
