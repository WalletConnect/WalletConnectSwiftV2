import Foundation

struct ChatInviteKeyClaims: JWTEncodable {
    let iss: String
    let sub:  String
    let aud:  String
    let iat:  Int
    let exp:  Int
    let pkh:  String
}

struct ChatInviteProposalClaims: JWTEncodable {
    let iss: String
    let iat: Int
    let exp: Int
    let ksu: String

    let aud: String // responder/invitee blockchain account (did:pkh)
    let sub: String // opening message included in the invite
    let pke: String // proposer/inviter public key (did:key)
}

struct ChatInviteApprovalClaims: JWTEncodable {
    let iss: String
    let iat: Int
    let exp: Int
    let ksu: String

    let aud:  String // proposer/inviter blockchain account (did:pkh)
    let sub:  String // public key sent by the responder/invitee
}

struct ChatMessageClaims: JWTEncodable {
    let iss: String
    let iat: Int
    let exp: Int
    let ksu: String

    let aud: String // recipient blockchain account (did:pkh)
    let sub: String // message sent by the author account

    // TODO: Media not implemented
    // let xma: Media?
}

struct ChatReceiptClaims: JWTEncodable {
    let iss: String
    let iat: Int
    let exp: Int
    let ksu: String

    let aud:  String // sender blockchain account (did:pkh)
    let sub:  String // hash of the message received
}
