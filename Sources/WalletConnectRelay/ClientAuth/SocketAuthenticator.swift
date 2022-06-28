import Foundation
import WalletConnectKMS

protocol SocketAuthenticating {
    func createAuthToken() throws -> String
}

struct SocketAuthenticator: SocketAuthenticating {
    private let authChallengeProvider: AuthChallengeProviding
    private let clientIdStorage: ClientIdStoring
    private let didKeyFactory: DIDKeyFactory

    init(authChallengeProvider: AuthChallengeProviding = AuthChallengeProvider(),
         clientIdStorage: ClientIdStoring,
         didKeyFactory: DIDKeyFactory = ED25519DIDKeyFactory()) {
        self.authChallengeProvider = authChallengeProvider
        self.clientIdStorage = clientIdStorage
        self.didKeyFactory = didKeyFactory
    }

    func createAuthToken() throws -> String {
        let clientIdKeyPair = try clientIdStorage.getOrCreateKeyPair()
        let challenge = try authChallengeProvider.getChallenge(for: clientIdKeyPair.publicKey.hexRepresentation)
        return try signJWT(subject: challenge, keyPair: clientIdKeyPair)
    }

    private func signJWT(subject: String, keyPair: SigningPrivateKey) throws -> String {
        let issuer = didKeyFactory.make(pubKey: keyPair.publicKey.rawRepresentation)
        let claims = JWT.Claims(iss: issuer, sub: subject)
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        return try jwt.encoded()
    }
}
