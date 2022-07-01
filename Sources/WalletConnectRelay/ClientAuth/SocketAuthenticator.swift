import Foundation
import WalletConnectKMS

protocol SocketAuthenticating {
    func createAuthToken() throws -> String
}

struct SocketAuthenticator: SocketAuthenticating {
    private let clientIdStorage: ClientIdStoring
    private let didKeyFactory: DIDKeyFactory

    init(clientIdStorage: ClientIdStoring, didKeyFactory: DIDKeyFactory = ED25519DIDKeyFactory()) {
        self.clientIdStorage = clientIdStorage
        self.didKeyFactory = didKeyFactory
    }

    func createAuthToken() throws -> String {
        let clientIdKeyPair = try clientIdStorage.getOrCreateKeyPair()
        let subject = generateSubject()
        return try signJWT(subject: subject, keyPair: clientIdKeyPair)
    }

    private func signJWT(subject: String, keyPair: SigningPrivateKey) throws -> String {
        let issuer = didKeyFactory.make(pubKey: keyPair.publicKey.rawRepresentation, prefix: true)
        let claims = JWT.Claims(iss: issuer, sub: subject)
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        return try jwt.encoded()
    }

    private func generateSubject() -> String {
        return Data.randomBytes(count: 32).toHexString()
    }
}
