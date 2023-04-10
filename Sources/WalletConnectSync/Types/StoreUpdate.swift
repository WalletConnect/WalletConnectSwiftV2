import Foundation

public enum StoreUpdate {
    case set(AnyCodable)
    case delete(String)
}

public struct StoreSet<Object: SyncObject>: Codable, Equatable {
    public let key: String
    public let value: Object
}

public struct StoreDelete: Codable, Equatable {
    public let key: String
}
