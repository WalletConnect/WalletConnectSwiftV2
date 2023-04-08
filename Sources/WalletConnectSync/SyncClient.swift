import Foundation
import Combine

public final class SyncClient {

    public var updatePublisher: AnyPublisher<SyncUpdate, Never> {
        return syncStorage.syncUpdatePublisher
    }

    private let syncStorage: SyncStorage

    init(syncStorage: SyncStorage) {
        self.syncStorage = syncStorage
    }

    /// Get message to sign for an account
    public func getMessage(account: Account) -> String {
        return """
        I authorize this app to sync my account: \(account.absoluteString)

        Read more about Sync API: https://docs.walletconnect.com/2.0/specs/clients/sync
        """
    }

    /// Register an account to sync
    public func register(account: Account, signature: CacaoSignature) throws {
        try syncStorage.saveIdentityKey(signature.s, for: account)
    }

    /// Create a store
    public func create(account: Account, store: String) async throws {
        fatalError()
    }

    // Set value to store
    public func set(account: Account, store: String, key: String, value: String) async throws {
        fatalError()
    }

    // Set value from store by key
    public func delete(account: Account, store: String, key: String) async throws {
        fatalError()
    }

    // Get stores
    public func getStores(account: Account) -> StoreMap {
        fatalError()
    }
}
