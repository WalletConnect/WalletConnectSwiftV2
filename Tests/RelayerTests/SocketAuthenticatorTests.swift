import Foundation
import XCTest
@testable import WalletConnectRelay

final class SocketAuthenticatorTests: XCTestCase {
    var authChallengeProvider: AuthChallengeProviding!
    var clientIdStorage: ClientIdStoring!
    var sut: SocketAuthenticator!

    override func setUp() {
        authChallengeProvider = AuthChallengeProviderMock()
        clientIdStorage = ClientIdStorageMock()
        sut = SocketAuthenticator(authChallengeProvider: authChallengeProvider, clientIdStorage: clientIdStorage)
    }

    func test() {

    }
}

