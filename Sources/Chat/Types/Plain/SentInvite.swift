import Foundation

public struct SentInvite: Codable, Equatable {
    public let id: Int64
    public let message: String
    public let inviterAccount: Account
    public let inviteeAccount: Account
    public let timestamp: UInt64
    public var status: Status

    public init(
        id: Int64,
        message: String,
        inviterAccount: Account,
        inviteeAccount: Account,
        timestamp: UInt64,
        status: SentInvite.Status = .pending // TODO: Implement statuses
    ) {
        self.id = id
        self.message = message
        self.inviterAccount = inviterAccount
        self.inviteeAccount = inviteeAccount
        self.timestamp = timestamp
        self.status = status
    }

    init(invite: SentInvite, status: Status) {
        self.init(
            id: invite.id,
            message: invite.message,
            inviterAccount: invite.inviterAccount,
            inviteeAccount: invite.inviteeAccount,
            timestamp: invite.timestamp,
            status: status
        )
    }
}

extension SentInvite {

    public enum Status: String, Codable, Equatable {
        case pending
        case approved
        case rejected
    }
}
