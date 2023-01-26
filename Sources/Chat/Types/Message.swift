import Foundation

public struct Message: Codable, Equatable {
    public let topic: String
    public let message: String
    public let authorAccount: Account
    public let timestamp: Int64

    init(topic: String, message: String, authorAccount: Account, timestamp: Int64) {
        self.topic = topic
        self.message = message
        self.authorAccount = authorAccount
        self.timestamp = timestamp
    }

    init(topic: String, payload: MessagePayload) {
        self.topic = topic
        self.message = payload.message
        self.authorAccount = payload.authorAccount
        self.timestamp = payload.timestamp
    }
}

struct MessagePayload: Codable {
    let message: String
    let authorAccount: Account
    let timestamp: Int64
}
