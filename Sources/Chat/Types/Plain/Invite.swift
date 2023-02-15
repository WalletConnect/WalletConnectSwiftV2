import Foundation

public struct Invite: Codable, Equatable {
    public let message: String
    public let inviterAccount: Account
    public let inviteeAccount: Account
    public let inviteePublicKey: String

    public init(
        message: String,
        inviterAccount: Account,
        inviteeAccount: Account,
        inviteePublicKey: String
    ) {
        self.message = message
        self.inviterAccount = inviterAccount
        self.inviteeAccount = inviteeAccount
        self.inviteePublicKey = inviteePublicKey
    }
}
