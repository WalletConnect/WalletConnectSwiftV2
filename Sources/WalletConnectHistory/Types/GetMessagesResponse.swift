import Foundation

public struct GetMessagesResponse: Codable {
    public let topic: String
    public let direction: GetMessagesPayload.Direction
    public let nextId: Int64?
    public let messages: [String]
}
