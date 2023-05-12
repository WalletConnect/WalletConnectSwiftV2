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

        // TODO: Resubscription service
    }

    /// Get message to sign for an account
    public func getMessage(account: Account) -> String {
        return """
        I authorize this app to sync my account: \(account.absoluteString)

        Read more about Sync API: https://docs.walletconnect.com/2.0/specs/clients/core/sync
        """
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

    // Set value to store
    public func set<Object: SyncObject>(
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
