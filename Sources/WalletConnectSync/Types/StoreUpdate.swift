import Foundation

public enum StoreUpdate: Codable {
    case set(StoreSet)
    case delete(StoreDelete)
}

public struct StoreSet: Codable {
    public let id: UInt64
    public let key: String
    public let value: String
}

public struct StoreDelete: Codable {
    public let id: UInt64
    public let key: String
}
