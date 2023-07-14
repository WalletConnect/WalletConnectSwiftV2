import Foundation

public struct PushMessageRecord: Codable, Equatable, DatabaseObject {
    public let id: String
    public let topic: String
    public let message: PushMessage
    public let publishedAt: Date

    public var databaseId: String {
        return id
    }
}
