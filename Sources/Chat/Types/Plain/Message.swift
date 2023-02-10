import Foundation

public struct Message: Codable, Equatable {
    public let topic: String
    public let message: String
    public let authorAccount: Account
    public let recipientAccount: Account
    public let timestamp: Int

    init(topic: String, message: String, authorAccount: Account, recipientAccount: Account, timestamp: Int) {
        self.topic = topic
        self.message = message
        self.authorAccount = authorAccount
        self.recipientAccount = recipientAccount
        self.timestamp = timestamp
    }
}
