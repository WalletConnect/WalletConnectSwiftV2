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

    let walletAccount = Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!
    let prvKey = Data(hex: "462c1dad6832d7d96ccf87bd6a686a4110e114aaaebd5512e552c0e3a87b480f")
    let eip1271Signature = "0xc1505719b2504095116db01baaf276361efd3a73c28cf8cc28dabefa945b8d536011289ac0a3b048600c1e692ff173ca944246cf7ceb319ac2262d27b395c82b1c"
    private var publishers = [AnyCancellable]()

    override func setUp() {
        setupClients()
    }

    private func setupClients(iatProvider: IATProvider = DefaultIATProvider()) {
        (appPairingClient, appAuthClient) = makeClients(prefix: "🤖 App", iatProvider: iatProvider)
        (walletPairingClient, walletAuthClient) = makeClients(prefix: "🐶 Wallet", iatProvider: iatProvider)
    }

    func makeClients(prefix: String, iatProvider: IATProvider) -> (PairingClient, AuthClient) {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: InputConfig.relayHost, projectId: InputConfig.projectId, keychainStorage: keychain, socketFactory: DefaultSocketFactory(), logger: logger)
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
            projectId: InputConfig.projectId,
            signerFactory: DefaultSignerFactory(),
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient,
            pairingRegisterer: pairingClient,
            iatProvider: iatProvider)

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
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create(projectId: InputConfig.projectId)
                let payload = try! request.payload.cacaoPayload(address: walletAccount.address)
                let signature = try! signer.sign(payload: payload, privateKey: prvKey, type: .eip191)
                try! await walletAuthClient.respond(requestId: request.id, signature: signature, from: walletAccount)
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

    func testEIP1271RespondSuccess() async {
        setupClients(iatProvider: IATProviderMock())

        let account = Account(chainIdentifier: "eip155:1", address: "0x2faf83c542b68f1b4cdc0e770e8cb9f567b08f71")!

        let responseExpectation = expectation(description: "successful response delivered")
        let uri = try! await appPairingClient.create()
        try! await appAuthClient.request(RequestParams(
            domain: "localhost",
            chainId: "eip155:1",
            nonce: "1665443015700",
            aud: "http://localhost:3000/",
            nbf: nil,
            exp: "2022-10-11T23:03:35.700Z",
            statement: nil,
            requestId: nil,
            resources: nil
        ), topic: uri.topic)

        try! await walletPairingClient.pair(uri: uri)
        walletAuthClient.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                let signature = CacaoSignature(t: .eip1271, s: eip1271Signature)
                try! await walletAuthClient.respond(requestId: request.id, signature: signature, from: account)
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

    func testEIP191RespondError() async {
        let responseExpectation = expectation(description: "error response delivered")
        let uri = try! await appPairingClient.create()
        try! await appAuthClient.request(RequestParams.stub(), topic: uri.topic)

        try! await walletPairingClient.pair(uri: uri)
        walletAuthClient.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                let signature = CacaoSignature(t: .eip1271, s: eip1271Signature)
                try! await walletAuthClient.respond(requestId: request.id, signature: signature, from: walletAccount)
            }
        }
        .store(in: &publishers)
        appAuthClient.authResponsePublisher.sink { (_, result) in
            guard case let .failure(error) = result, error == .signatureVerificationFailed else { XCTFail(); return }
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
                try! await walletAuthClient.respond(requestId: request.id, signature: cacaoSignature, from: walletAccount)
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

private struct IATProviderMock: IATProvider {
    var iat: String {
        return "2022-10-10T23:03:35.700Z"
    }
}
