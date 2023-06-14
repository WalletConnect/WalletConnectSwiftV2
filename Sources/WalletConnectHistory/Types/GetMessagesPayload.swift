import Foundation

public struct GetMessagesPayload: Codable {
    public enum Direction: String, Codable {
        case forward
        case backward
    }
    public let topic: String
    public let originId: Int64?
    public let messageCount: Int?
    public let direction: Direction

    public init(topic: String, originId: Int64?, messageCount: Int?, direction: GetMessagesPayload.Direction) {
        self.topic = topic
        self.originId = originId
        self.messageCount = messageCount
        self.direction = direction
    }
}
