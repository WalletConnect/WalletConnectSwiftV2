import Foundation

public struct ChatInviteKeyClaims: JWTEncodable {
    public let iss: String
    public let sub:  String
    public let aud:  String
    public let iat:  Int
    public let exp:  Int
    public let pkh:  String
}

public struct ChatInviteProposalClaims: JWTEncodable {
    public let iss: String
    public let iat: Int
    public let exp: Int
    public let ksu: String

    public let aud: String // responder/invitee blockchain account (did:pkh)
    public let sub: String // opening message included in the invite
    public let pke: String // proposer/inviter public key (did:key)
}

public struct ChatInviteApprovalClaims: JWTEncodable {
    public let iss: String
    public let iat: Int
    public let exp: Int
    public let ksu: String

    public let aud:  String // proposer/inviter blockchain account (did:pkh)
    public let sub:  String // public key sent by the responder/invitee
}

public struct ChatMessageClaims: JWTEncodable {
    public let iss: String
    public let iat: Int
    public let exp: Int
    public let ksu: String

    public let aud: String // recipient blockchain account (did:pkh)
    public let sub: String // message sent by the author account

    // TODO: Media not implemented
    // public let xma: Media?
}

public struct ChatReceiptClaims: JWTEncodable {
    public let iss: String
    public let iat: Int
    public let exp: Int
    public let ksu: String

    public let aud:  String // sender blockchain account (did:pkh)
    public let sub:  String // hash of the message received
}
