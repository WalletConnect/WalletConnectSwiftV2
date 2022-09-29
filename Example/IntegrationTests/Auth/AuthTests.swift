import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
@testable import Auth
import WalletConnectPairing

final class AuthTests: XCTestCase {
    var app: AuthClient!
    var wallet: AuthClient!
    let prvKey = Data(hex: "462c1dad6832d7d96ccf87bd6a686a4110e114aaaebd5512e552c0e3a87b480f")
    private var publishers = [AnyCancellable]()

    override func setUp() {
        app = makeClient(prefix: "👻 App")
        let walletAccount = Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!
        wallet = makeClient(prefix: "🤑 Wallet", account: walletAccount)
    }

    func makeClient(prefix: String, account: Account? = nil) -> AuthClient {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let projectId = "3ca2919724fbfa5456a25194e369a8b4"
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: URLConfig.relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)
        let keyValueStorage = RuntimeKeyValueStorage()

        let pairingClient = PairingClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            relayClient: relayClient)

        return AuthClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            account: account,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            relayClient: relayClient,
            pairingClient: pairingClient)
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
        wallet.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                let signature = try! MessageSigner().sign(message: request.message, privateKey: prvKey)
                try! await wallet.respond(requestId: request.id, signature: signature)
            }
        }
        .store(in: &publishers)
        app.authResponsePublisher.sink { (_, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [responseExpectation], timeout: 5)
    }

    func testUserRespondError() async {
        let responseExpectation = expectation(description: "error response delivered")
        let uri = try! await app.request(RequestParams.stub())
        try! await wallet.pair(uri: uri)
        wallet.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                try! await wallet.reject(requestId: request.id)
            }
        }
        .store(in: &publishers)
        app.authResponsePublisher.sink { (_, result) in
            guard case .failure(let error) = result else { XCTFail(); return }
            XCTAssertEqual(error, .userRejeted)
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [responseExpectation], timeout: 5)
    }

    func testRespondSignatureVerificationFailed() async {
        let responseExpectation = expectation(description: "invalid signature response delivered")
        let uri = try! await app.request(RequestParams.stub())
        try! await wallet.pair(uri: uri)
        wallet.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                let invalidSignature = "438effc459956b57fcd9f3dac6c675f9cee88abf21acab7305e8e32aa0303a883b06dcbd956279a7a2ca21ffa882ff55cc22e8ab8ec0f3fe90ab45f306938cfa1b"
                let cacaoSignature = CacaoSignature(t: "eip191", s: invalidSignature)
                try! await wallet.respond(requestId: request.id, signature: cacaoSignature)
            }
        }
        .store(in: &publishers)
        app.authResponsePublisher.sink { (_, result) in
            guard case .failure(let error) = result else { XCTFail(); return }
            XCTAssertEqual(error, .signatureVerificationFailed)
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [responseExpectation], timeout: 2)
    }
// TODO - uncomment
//    func testPing() async {
//        let pingExpectation = expectation(description: "expects ping response")
//        let uri = try! await app.request(RequestParams.stub())
//        try! await wallet.pair(uri: uri)
//        try! await wallet.ping(topic: uri.topic)
//        wallet.pingResponsePublisher
//            .sink { topic in
//                XCTAssertEqual(topic, uri.topic)
//                pingExpectation.fulfill()
//            }
//            .store(in: &publishers)
//        wait(for: [pingExpectation], timeout: 5)
//    }
}
