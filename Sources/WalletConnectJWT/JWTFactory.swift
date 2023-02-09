import Foundation

public struct JWTFactory {

    private let keyPair: SigningPrivateKey

    public init(keyPair: SigningPrivateKey) {
        self.keyPair = keyPair
    }

    public func createRelayJWT(
        sub: String,
        aud: String
    ) throws -> String {
        let claims = RelayClaims(iss: getIss(), sub: sub, aud: aud, iat: getIat(), exp: expiry(days: 1))
        return try createAndSignJWT(claims: claims)
    }

    public func createChatInviteJWT(
        sub: String,
        aud: String,
        pkh: String
    ) throws -> String {
        let claims = ChatInviteKeyClaims(iss: getIss(), sub: sub, aud: aud, iat: getIat(), exp: getChatExp(), pkh: pkh)
        return try createAndSignJWT( claims: claims)
    }

    public func createChatInviteProposalJWT(
        ksu: String,
        aud: String,
        sub: String,
        pke: String
    ) throws -> String {
        let claims = ChatInviteProposalClaims(iss: getIss(), iat: getIat(), exp: getChatExp(), ksu: ksu, aud: aud, sub: sub, pke: pke)
        return try createAndSignJWT( claims: claims)
    }
    public func createChatInviteApprovalJWT(
        ksu: String,
        aud: String,
        sub: String
    ) throws -> String {
        let claims = ChatInviteApprovalClaims(iss: getIss(), iat: getIat(), exp: getChatExp(), ksu: ksu, aud: aud, sub: sub)
        return try createAndSignJWT( claims: claims)
    }

    public func createChatMessageJWT(
        ksu: String,
        aud: String,
        sub: String
    ) throws -> String {
        let claims = ChatMessageClaims(iss: getIss(), iat: getIat(), exp: getChatExp(), ksu: ksu, aud: aud, sub: sub)
        return try createAndSignJWT( claims: claims)
    }

    public func createChatReceiptJWT(
        ksu: String,
        aud:  String,
        sub:  String
    ) throws -> String {
        let claims = ChatReceiptClaims(iss: getIss(), iat: getIat(), exp: getChatExp(), ksu: ksu, aud: aud, sub: sub)
        return try createAndSignJWT( claims: claims)
    }
}

private extension JWTFactory {

    func createAndSignJWT<JWTClaims: JWTEncodable>(
        claims: JWTClaims
    ) throws -> String {
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        return try jwt.encoded()
    }

    func getIat() -> Int {
        return Int(Date().timeIntervalSince1970)
    }

    func getIss() -> String {
        return keyPair.DIDKey
    }

    func getChatExp() -> Int {
        return expiry(days: 30)
    }

    func expiry(days: Int) -> Int {
        var components = DateComponents()
        components.setValue(days, for: .day)
        let date = Calendar.current.date(byAdding: components, to: Date())!
        return Int(date.timeIntervalSince1970)
    }
}
