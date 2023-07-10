import Foundation

public struct GetMessagesResponse: Decodable {
    public struct Message: Codable {
        public let message: String
    }
    public let topic: String
    public let direction: GetMessagesPayload.Direction
    public let nextId: Int64?
    public let messages: [String]

    enum CodingKeys: String, CodingKey {
        case topic
        case direction
        case nextId
        case messages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.topic = try container.decode(String.self, forKey: .topic)
        self.direction = try container.decode(GetMessagesPayload.Direction.self, forKey: .direction)
        self.nextId = try container.decodeIfPresent(Int64.self, forKey: .nextId)

        let messages = try container.decode([Message].self, forKey: .messages)
        self.messages = messages.map { $0.message }
    }
}
