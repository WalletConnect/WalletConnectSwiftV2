import Foundation
@testable import WalletConnectKMS

public final class KeychainStorageMock: KeychainStorageProtocol {

    public var storage: [String: Data]

    private(set) var didCallAdd = false
    private(set) var didCallRead = false
    private(set) var didCallDelete = false

    public init(storage: [String: Data] = [:]) {
        self.storage = storage
    }

    public func add<T>(_ item: T, forKey key: String) throws where T: GenericPasswordConvertible {
        didCallAdd = true
        storage[key] = item.rawRepresentation
    }

    public func read<T>(key: String) throws -> T where T: GenericPasswordConvertible {
        didCallRead = true
        if let data = storage[key] {
            return try T(rawRepresentation: data)
        }
        throw KeychainError(errSecItemNotFound)
    }

    public func delete(key: String) throws {
        didCallDelete = true
        storage[key] = nil
    }

    public func deleteAll() throws {
        storage = [:]
    }
}
