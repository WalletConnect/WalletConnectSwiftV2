import Foundation

public struct Invite: Codable, Equatable {
    public let id: Int64
    public let topic: String
    public let message: String
    public let account: Account
    public let publicKey: String

    init(id: Int64, topic: String, payload: InvitePayload) {
        self.id = id
        self.topic = topic
        self.message = payload.message
        self.account = payload.account
        self.publicKey = payload.publicKey
    }
}

struct InviteResponse: Codable {
    let publicKey: String
}

struct InvitePayload: Codable {
    let message: String
    let account: Account
    let publicKey: String
}
