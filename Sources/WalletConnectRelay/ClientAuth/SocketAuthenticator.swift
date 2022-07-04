import Foundation
import WalletConnectKMS

protocol SocketAuthenticating {
    func createAuthToken() throws -> String
}

struct SocketAuthenticator: SocketAuthenticating {
    private let clientIdStorage: ClientIdStoring
    private let didKeyFactory: DIDKeyFactory
    private let audience = "wss://relay.walletconnect.com"

    init(clientIdStorage: ClientIdStoring, didKeyFactory: DIDKeyFactory) {
        self.clientIdStorage = clientIdStorage
        self.didKeyFactory = didKeyFactory
    }

    func createAuthToken() throws -> String {
        let clientIdKeyPair = try clientIdStorage.getOrCreateKeyPair()
        let subject = generateSubject()
        return try createAndSignJWT(subject: subject, keyPair: clientIdKeyPair)
    }

    private func createAndSignJWT(subject: String, keyPair: SigningPrivateKey) throws -> String {
        let issuer = didKeyFactory.make(pubKey: keyPair.publicKey.rawRepresentation, prefix: true)
        let claims = JWT.Claims(iss: issuer, sub: subject, aud: audience, iat: Date(), exp: getExpiry())
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        return try jwt.encoded()
    }

    private func generateSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }

    private func getExpiry() -> Date {
        var components = DateComponents()
        components.setValue(1, for: .day)
        // safe to unwrap as the date must be calculated
        return Calendar.current.date(byAdding: components, to: Date())!
    }
}
