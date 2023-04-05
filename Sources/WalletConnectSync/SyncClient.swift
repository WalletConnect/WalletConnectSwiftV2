import Foundation
import Combine

public final class SyncClient {

    private let updateSubject = PassthroughSubject<SyncUpdate, Never>()

    public var updatePublisher: AnyPublisher<SyncUpdate, Never> {
        return updateSubject.eraseToAnyPublisher()
    }

    public init() {
        
    }

    /// Get message to sign for an account
    public func getMessage(account: Account) async throws -> String {
        fatalError()
    }

    /// Register an account to sync
    public func register(account: Account, signature: CacaoSignature) async throws {
        fatalError()
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
