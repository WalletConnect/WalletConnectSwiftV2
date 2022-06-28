import Foundation
import WalletConnectKMS

protocol SocketAuthenticating {
    func createAuthToken() async throws -> String
}

actor SocketAuthenticator: SocketAuthenticating {
    private let authChallengeProvider: AuthChallengeProviding
    private let clientIdStorage: ClientIdStoring
    private let didKeyFactory: DIDKeyFactory

    init(authChallengeProvider: AuthChallengeProviding,
         clientIdStorage: ClientIdStoring,
         didKeyFactory: DIDKeyFactory = ED25519DIDKeyFactory()) {
        self.authChallengeProvider = authChallengeProvider
        self.clientIdStorage = clientIdStorage
        self.didKeyFactory = didKeyFactory
    }

    func createAuthToken() async throws -> String {
        let clientIdKeyPair = try await clientIdStorage.getOrCreateKeyPair()
        let challenge = try await authChallengeProvider.getChallenge(for: clientIdKeyPair.publicKey.hexRepresentation)
        return try await signJWT(subject: challenge.nonce, keyPair: clientIdKeyPair)
    }

    private func signJWT(subject: String, keyPair: SigningPrivateKey) async throws -> String {
        let issuer = await didKeyFactory.make(pubKey: keyPair.publicKey.rawRepresentation)
        let claims = JWT.Claims(iss: issuer, sub: subject)
        var jwt = JWT(claims: claims)
        try jwt.sign(using: EdDSASigner(keyPair))
        return try jwt.encoded()
    }
}
