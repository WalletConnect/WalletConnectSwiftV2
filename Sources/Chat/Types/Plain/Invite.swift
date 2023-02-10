import Foundation

public struct Invite: Codable, Equatable {
    public let id: Int64
    public let topic: String
    public let message: String
    public let account: Account
    public let publicKey: String

    init(id: Int64, topic: String, message: String, account: Account, publicKey: String) {
        self.id = id
        self.topic = topic
        self.message = message
        self.account = account
        self.publicKey = publicKey
    }
}
