import Foundation

public struct Message: Codable, Equatable {
    public let topic: String
    public let message: String
    public let authorAccount: Account
    public let timestamp: UInt64
    public let media: Media?

    init(
        topic: String,
        message: String,
        authorAccount: Account,
        timestamp: UInt64,
        media: Message.Media? = nil // TODO: Implement media
    ) {
        self.topic = topic
        self.message = message
        self.authorAccount = authorAccount
        self.timestamp = timestamp
        self.media = media
    }
}

extension Message {

    public struct Media: Codable, Equatable {
        let type: String
        let data: String // Character limit is 500. Must be checked by SDK before sending
    }
}
