import Foundation

public struct ReceivedInvite: Codable, Equatable {
    public let id: Int64
    public let message: String
    public let inviterAccount: Account
    public let inviteeAccount: Account
    public let inviterPublicKey: String
    public let inviteePublicKey: String
    public var status: Status

    public init(
        id: Int64,
        message: String,
        inviterAccount: Account,
        inviteeAccount: Account,
        inviterPublicKey: String,
        inviteePublicKey: String,
        status: Status = .pending // TODO: Implement statuses
    ) {
        self.id = id
        self.message = message
        self.inviterAccount = inviterAccount
        self.inviteeAccount = inviteeAccount
        self.inviterPublicKey = inviterPublicKey
        self.inviteePublicKey = inviteePublicKey
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
            status: status
        )
    }
}

extension ReceivedInvite {

    public enum Status: Codable, Equatable {
        case pending
        case rejected
        case approved
    }
}
