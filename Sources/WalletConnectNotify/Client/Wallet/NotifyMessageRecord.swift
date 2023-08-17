import Foundation

public struct NotifyMessageRecord: Codable, Equatable, DatabaseObject {
    public let id: String
    public let topic: String
    public let message: NotifyMessage
    public let publishedAt: Date

    public var databaseId: String {
        return id
    }
}
