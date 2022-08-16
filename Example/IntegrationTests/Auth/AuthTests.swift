import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
@testable import Auth

final class AuthTests: XCTestCase {
    var app: AuthClient!
    var wallet: AuthClient!
    private var publishers = [AnyCancellable]()

    override func setUp() {
        registry = KeyValueRegistry()
        app = makeClient(prefix: "👻 App")
        wallet = makeClient(prefix: "🤑 Wallet")

        let expectation = expectation(description: "Wait Clients Connected")
        expectation.expectedFulfillmentCount = 2

        app.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                expectation.fulfill()
            }
        }.store(in: &publishers)

        wallet.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                expectation.fulfill()
            }
        }.store(in: &publishers)

        wait(for: [expectation], timeout: 5)

    }


    func makeClient(prefix: String) -> AuthClient {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let relayHost = "relay.walletconnect.com"
        let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)
        return AuthClientFactory()
    }

    func testRequest() async {
        let inviteExpectation = expectation(description: "invitation expectation")
        let inviteeAccount = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        let inviterAccount = Account(chainIdentifier: "eip155:1", address: "0x36275231673672234423f")!
        let pubKey = try! await invitee.register(account: inviteeAccount)
        try! await inviter.invite(publicKey: pubKey, peerAccount: inviteeAccount, openingMessage: "", account: inviterAccount)
        invitee.invitePublisher.sink { _ in
            inviteExpectation.fulfill()
        }.store(in: &publishers)
        wait(for: [inviteExpectation], timeout: 4)
    }
}
