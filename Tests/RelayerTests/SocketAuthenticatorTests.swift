import Foundation
import XCTest
@testable import WalletConnectRelay

final class SocketAuthenticatorTests: XCTestCase {
    var authChallengeProvider: AuthChallengeProviderMock!
    var clientIdStorage: ClientIdStorageMock!
    var sut: SocketAuthenticator!

    override func setUp() {
        authChallengeProvider = AuthChallengeProviderMock()
        clientIdStorage = ClientIdStorageMock()
        sut = SocketAuthenticator(authChallengeProvider: authChallengeProvider, clientIdStorage: clientIdStorage)
    }

    func test() {
        authChallengeProvider.challange = "c479fe5dc464e771e78b193d239a65b58d278cad1c34bfb0b5716e5bb514928e"
//        clientIdStorage.keyPair =
        sut.createAuthToken()
    }
}
