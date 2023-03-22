import Foundation

public struct ReceivedInvite: Codable, Equatable {
    public let id: Int64
    public let message: String
    public let inviterAccount: Account
    public let inviteeAccount: Account
    public let inviterPublicKey: String
    public let inviteePublicKey: String
    public let timestamp: UInt64
    public var status: Status

    public init(
        id: Int64,
        message: String,
        inviterAccount: Account,
        inviteeAccount: Account,
        inviterPublicKey: String,
        inviteePublicKey: String,
        timestamp: UInt64,
        status: Status = .pending
    ) {
        self.id = id
        self.message = message
        self.inviterAccount = inviterAccount
        self.inviteeAccount = inviteeAccount
        self.inviterPublicKey = inviterPublicKey
        self.inviteePublicKey = inviteePublicKey
        self.timestamp = timestamp
        self.status = status
    }

    init(invite: ReceivedInvite, status: Status) {
        self.init(
            id: invite.id,
            message: invite.message,
            inviterAccount: invite.inviterAccount,
            inviteeAccount: invite.inviteeAccount,
            inviterPublicKey: invite.inviterPublicKey,
            inviteePublicKey: invite.inviteePublicKey,
            timestamp: invite.timestamp,
            status: status
        )
    }
}

extension ReceivedInvite {

    public enum Status: String, Codable, Equatable {
        case pending
        case rejected
        case approved
    }
}
