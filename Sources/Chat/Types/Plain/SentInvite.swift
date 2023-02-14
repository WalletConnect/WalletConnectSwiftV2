import Foundation

public struct SentInvite: Codable, Equatable {
    public let id: Int64
    public let message: String
    public let inviterAccount: Account
    public let inviteeAccount: Account
    public let timestamp: Int64
    public var status: Status

    public init(
        id: Int64,
        message: String,
        inviterAccount: Account,
        inviteeAccount: Account,
        inviterPublicKey: String,
        inviteePublicKey: String,
        timestamp: Int64,
        status: SentInvite.Status = .pending // TODO: Implement statuses
    ) {
        self.id = id
        self.message = message
        self.inviterAccount = inviterAccount
        self.inviteeAccount = inviteeAccount
        self.timestamp = timestamp
        self.status = status
    }
}

extension SentInvite {

    public enum Status: Codable, Equatable {
        case pending
        case rejected
    }
}
