import Foundation
import XCTest
import WalletConnectKMS
@testable import WalletConnectRelay

final class SocketAuthenticatorTests: XCTestCase {
    var authChallengeProvider: AuthChallengeProviderMock!
    var clientIdStorage: ClientIdStorageMock!
    var sut: SocketAuthenticator!
    let expectedToken =  "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkaWQ6a2V5Ono2TWtvZEhad25lVlJTaHRhTGY4SktZa3hwREdwMXZHWm5wR21kQnBYOE0yZXh4SCIsInN1YiI6ImM0NzlmZTVkYzQ2NGU3NzFlNzhiMTkzZDIzOWE2NWI1OGQyNzhjYWQxYzM0YmZiMGI1NzE2ZTViYjUxNDkyOGUifQ.0JkxOM-FV21U7Hk-xycargj_qNRaYV2H5HYtE4GzAeVQYiKWj7YySY5AdSqtCgGzX4Gt98XWXn2kSr9rE1qvCA"

    override func setUp() {
        authChallengeProvider = AuthChallengeProviderMock()
        clientIdStorage = ClientIdStorageMock()
        sut = SocketAuthenticator(authChallengeProvider: authChallengeProvider, clientIdStorage: clientIdStorage)
    }

    func test() async {
        authChallengeProvider.challange = "c479fe5dc464e771e78b193d239a65b58d278cad1c34bfb0b5716e5bb514928e"
        let keyRaw = Data(hex: "58e0254c211b858ef7896b00e3f36beeb13d568d47c6031c4218b87718061295")
        let signingKey = try! SigningPrivateKey(rawRepresentation: keyRaw)
        print(signingKey.publicKey.rawRepresentation.toHexString())
        clientIdStorage.keyPair = signingKey
        let token = try! await sut.createAuthToken()
        XCTAssertEqual(token, expectedToken)
    }
}

//
//const seed = fromString(
//  "58e0254c211b858ef7896b00e3f36beeb13d568d47c6031c4218b87718061295",
//  "base16"
//);
//
//// Generate key pair from seed
//const keyPair = ed25519.generateKeyPairFromSeed(seed);
//// secretKey = "58e0254c211b858ef7896b00e3f36beeb13d568d47c6031c4218b87718061295884ab67f787b69e534bfdba8d5beb4e719700e90ac06317ed177d49e5a33be5a"
//// publicKey = "884ab67f787b69e534bfdba8d5beb4e719700e90ac06317ed177d49e5a33be5a
