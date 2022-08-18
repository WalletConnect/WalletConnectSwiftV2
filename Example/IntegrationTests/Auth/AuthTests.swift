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
        let walletAccount = Account(chainIdentifier: "eip155:1", address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")!
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
        let requestExpectation = expectation(description: "request delivered to wallet")
        let uri = try! await app.request(RequestParams.stub())
        try! await wallet.pair(uri: uri)
        wallet.authRequestPublisher.sink { _ in
            requestExpectation.fulfill()
        }.store(in: &publishers)
        wait(for: [requestExpectation], timeout: 2)
    }

    func testRespondSuccess() async {
        let responseExpectation = expectation(description: "successful response delivered")
        let uri = try! await app.request(RequestParams.stub())
        try! await wallet.pair(uri: uri)
        wallet.authRequestPublisher.sink { [unowned self] (id, message) in
            Task(priority: .high) {
                print("responding")
                try! await wallet.respond(.success(RespondParams.stub(id: id)))
            }
        }
        .store(in: &publishers)
        app.authResponsePublisher.sink { (id, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [responseExpectation], timeout: 2)
    }
}

extension RespondParams {
    static func stub(id: RPCID) -> RespondParams {
        RespondParams(
            id: id,
            signature: CacaoSignature.stub())
    }
}

extension CacaoSignature {
    static func stub() -> CacaoSignature {
        return CacaoSignature(t: "eip191", s: "438effc459956b57fcd9f3dac6c675f9cee88abf21acab7305e8e32aa0303a883b06dcbd956279a7a2ca21ffa882ff55cc22e8ab8ec0f3fe90ab45f306938cfa1b")
    }
}
