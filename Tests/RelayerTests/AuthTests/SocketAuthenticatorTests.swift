import Foundation
import XCTest
import WalletConnectKMS
@testable import WalletConnectRelay

final class SocketAuthenticatorTests: XCTestCase {
    var authChallengeProvider: AuthChallengeProviderMock!
    var clientIdStorage: ClientIdStorageMock!
    var DIDKeyFactory: ED25519DIDKeyFactoryMock!
    var sut: SocketAuthenticator!
    let expectedToken =  "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkaWQ6a2V5Ono2TWtvZEhad25lVlJTaHRhTGY4SktZa3hwREdwMXZHWm5wR21kQnBYOE0yZXh4SCIsInN1YiI6ImM0NzlmZTVkYzQ2NGU3NzFlNzhiMTkzZDIzOWE2NWI1OGQyNzhjYWQxYzM0YmZiMGI1NzE2ZTViYjUxNDkyOGUifQ.0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"

    override func setUp() {
        authChallengeProvider = AuthChallengeProviderMock()
        clientIdStorage = ClientIdStorageMock()
        DIDKeyFactory = ED25519DIDKeyFactoryMock()
        DIDKeyFactory.did = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
        sut = SocketAuthenticator(
            authChallengeProvider: authChallengeProvider,
            clientIdStorage: clientIdStorage,
        didKeyFactory: DIDKeyFactory)
    }

    func test() async {
        authChallengeProvider.challenge = AuthChallenge(nonce: "c479fe5dc464e771e78b193d239a65b58d278cad1c34bfb0b5716e5bb514928e")
        let keyRaw = Data(hex: "58e0254c211b858ef7896b00e3f36beeb13d568d47c6031c4218b87718061295")
        let signingKey = try! SigningPrivateKey(rawRepresentation: keyRaw)
        clientIdStorage.keyPair = signingKey
        let token = try! sut.createAuthToken()
        XCTAssertNotNil(token)
    }
}
