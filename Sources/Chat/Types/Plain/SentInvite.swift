import Foundation

public struct SentInvite: Codable, Equatable {
    public let id: Int64
    public let message: String
    public let inviterAccount: Account
    public let inviteeAccount: Account
    public let inviterPubKeyY: String
    public let inviterPrivKeyY: String
    public let responseTopic: String
    public let symKey: String
    public let timestamp: UInt64
    public var status: Status

    init(
        id: Int64,
        message: String,
        inviterAccount: Account,
        inviteeAccount: Account,
        inviterPubKeyY: String,
        inviterPrivKeyY: String,
        responseTopic: String,
        symKey: String,
        timestamp: UInt64,
        status: SentInvite.Status = .pending
    ) {
        self.id = id
        self.message = message
        self.inviterAccount = inviterAccount
        self.inviteeAccount = inviteeAccount
        self.inviterPubKeyY = inviterPubKeyY
        self.inviterPrivKeyY = inviterPrivKeyY
        self.responseTopic = responseTopic
        self.symKey = symKey
        self.timestamp = timestamp
        self.status = status
    }

    init(invite: SentInvite, status: Status) {
        self.init(
            id: invite.id,
            message: invite.message,
            inviterAccount: invite.inviterAccount,
            inviteeAccount: invite.inviteeAccount,
            inviterPubKeyY: invite.inviterPubKeyY,
            inviterPrivKeyY: invite.inviterPrivKeyY,
            responseTopic: invite.responseTopic,
            symKey: invite.symKey,
            timestamp: invite.timestamp,
            status: status
        )
    }
}

extension SentInvite: DatabaseObject {

    public var databaseId: String {
        return responseTopic
    }
}

extension SentInvite {

    public enum Status: String, Codable, Equatable {
        case pending
        case approved
        case rejected
    }
}
