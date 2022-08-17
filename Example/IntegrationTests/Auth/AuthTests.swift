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
        app = makeClient(prefix: "👻 App")
        let walletAccount = Account(chainIdentifier: "eip155:1", address: "0x3627523167367216556273151")!
        wallet = makeClient(prefix: "🤑 Wallet", account: walletAccount)

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


    func makeClient(prefix: String, account: Account? = nil) -> AuthClient {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let relayHost = "relay.walletconnect.com"
        let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)

        return AuthClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            account: account,
            logger: logger,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            relayClient: relayClient)
    }

    func testRequest() async {
        let requestExpectation = expectation(description: "request")
        Task(priority: .high) {
            let uri = try await app.request(RequestParams.stub())
            try await wallet.pair(uri: uri)
        }
        wallet.authRequestPublisher.sink { _ in
            requestExpectation.fulfill()
        }.store(in: &publishers)
        wait(for: [requestExpectation], timeout: 2)
    }
}
