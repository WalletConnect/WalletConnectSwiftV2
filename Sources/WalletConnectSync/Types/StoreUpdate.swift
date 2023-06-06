import Foundation

public enum StoreUpdate {
    case set(StoreSet)
    case delete(StoreDelete)
}

public struct StoreSet: Codable, Equatable {
    public let key: String
    public let value: String
}

public struct StoreDelete: Codable, Equatable {
    public let key: String
}
