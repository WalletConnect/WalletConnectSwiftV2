import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
@testable import Auth
import WalletConnectPairing
import WalletConnectNetworking

final class AuthTests: XCTestCase {
    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appAuthClient: AuthClient!
    var walletAuthClient: AuthClient!
    let prvKey = Data(hex: "462c1dad6832d7d96ccf87bd6a686a4110e114aaaebd5512e552c0e3a87b480f")
    private var publishers = [AnyCancellable]()

    override func setUp() {
        let walletAccount = Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!

        (appPairingClient, appAuthClient) = makeClients(prefix: "🤖 App")
        (walletPairingClient, walletAuthClient) = makeClients(prefix: "🐶 Wallet", account: walletAccount)
    }

    func makeClients(prefix: String, account: Account? = nil) -> (PairingClient, AuthClient) {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: InputConfig.relayHost, projectId: InputConfig.projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)
        let keyValueStorage = RuntimeKeyValueStorage()

        let networkingClient = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: logger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage)

        let pairingClient = PairingClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient)

        let authClient = AuthClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            account: account,
            projectId: InputConfig.projectId,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient,
            pairingRegisterer: pairingClient)

        return (pairingClient, authClient)
    }

    func testRequest() async {
        let requestExpectation = expectation(description: "request delivered to wallet")
        let uri = try! await appPairingClient.create()
        try! await appAuthClient.request(RequestParams.stub(), topic: uri.topic)

        try! await walletPairingClient.pair(uri: uri)
        walletAuthClient.authRequestPublisher.sink { _ in
            requestExpectation.fulfill()
        }.store(in: &publishers)
        wait(for: [requestExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testEIP191RespondSuccess() async {
        let responseExpectation = expectation(description: "successful response delivered")
        let uri = try! await appPairingClient.create()
        try! await appAuthClient.request(RequestParams.stub(), topic: uri.topic)

        try! await walletPairingClient.pair(uri: uri)
        walletAuthClient.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                let signer = MessageSignerFactory.create(projectId: InputConfig.projectId)
                let signature = try! signer.sign(message: request.message, privateKey: prvKey, type: .eip191)
                try! await walletAuthClient.respond(requestId: request.id, signature: signature)
            }
        }
        .store(in: &publishers)
        appAuthClient.authResponsePublisher.sink { (_, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testUserRespondError() async {
        let responseExpectation = expectation(description: "error response delivered")
        let uri = try! await appPairingClient.create()
        try! await appAuthClient.request(RequestParams.stub(), topic: uri.topic)

        try! await walletPairingClient.pair(uri: uri)
        walletAuthClient.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                try! await walletAuthClient.reject(requestId: request.id)
            }
        }
        .store(in: &publishers)
        appAuthClient.authResponsePublisher.sink { (_, result) in
            guard case .failure(let error) = result else { XCTFail(); return }
            XCTAssertEqual(error, .userRejeted)
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testRespondSignatureVerificationFailed() async {
        let responseExpectation = expectation(description: "invalid signature response delivered")
        let uri = try! await appPairingClient.create()
        try! await appAuthClient.request(RequestParams.stub(), topic: uri.topic)

        try! await walletPairingClient.pair(uri: uri)
        walletAuthClient.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                let invalidSignature = "438effc459956b57fcd9f3dac6c675f9cee88abf21acab7305e8e32aa0303a883b06dcbd956279a7a2ca21ffa882ff55cc22e8ab8ec0f3fe90ab45f306938cfa1b"
                let cacaoSignature = CacaoSignature(t: .eip191, s: invalidSignature)
                try! await walletAuthClient.respond(requestId: request.id, signature: cacaoSignature)
            }
        }
        .store(in: &publishers)
        appAuthClient.authResponsePublisher.sink { (_, result) in
            guard case .failure(let error) = result else { XCTFail(); return }
            XCTAssertEqual(error, .signatureVerificationFailed)
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }
}
