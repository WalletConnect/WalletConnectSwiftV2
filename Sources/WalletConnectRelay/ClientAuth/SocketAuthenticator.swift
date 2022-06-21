import Foundation
import WalletConnectKMS


protocol SocketAuthenticationg {
    func createAuthToken() async throws -> String
}

actor SocketAuthenticator: SocketAuthenticationg {
    let authChallengeProvider: AuthChallengeProviding
    let clientIdStorage: ClientIdStoring

    init(authChallengeProvider: AuthChallengeProviding, clientIdStorage: ClientIdStoring) {
        self.authChallengeProvider = authChallengeProvider
        self.clientIdStorage = clientIdStorage
    }

    func createAuthToken() async throws -> String {
        let clientIdKeyPair = try await clientIdStorage.getOrCreateKeyPair()
        let challenge = try await authChallengeProvider.getChallenge(for: clientIdKeyPair.publicKey.hexRepresentation)
        return try signJWT(subject: challenge, keyPair: clientIdKeyPair)
    }

    func signJWT(subject: String, keyPair: AgreementPrivateKey) throws -> String {
        fatalError("not implemented")
    }
}

