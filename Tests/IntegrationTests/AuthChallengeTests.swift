import XCTest
import WalletConnectKMS
@testable import WalletConnectRelay

final class AuthChallengeTests: XCTestCase {

    let relayHost: String = "dev.relay.walletconnect.com"

    var httpClient: HTTPClient!
    var provider: AuthChallengeProvider!

    override func setUp() {
        httpClient = HTTPClient(host: relayHost)
        provider = AuthChallengeProvider(client: httpClient)
    }

    func testGetChallenge() async throws {
        let key = SigningPrivateKey().publicKey.hexRepresentation
        let challenge = try await provider.getChallenge(for: key)
        XCTAssertFalse(challenge.nonce.isEmpty)
    }
}
