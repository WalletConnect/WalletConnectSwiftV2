import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectPush
@testable import WalletConnectPairing
import Auth


final class PairingTests: XCTestCase {

    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appPushClient: PushClient!
    var walletPushClient: PushClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    func makeClients(prefix: String) -> (PairingClient, PushClient) {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage(prefix: prefix)

        let relayLogger = ConsoleLogger(suffix: prefix + " [Relay]", loggingLevel: .debug)
        let pairingLogger = ConsoleLogger(suffix: prefix + " [Pairing]", loggingLevel: .debug)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)

        let relayClient = RelayClient(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: SocketFactory(),
            logger: relayLogger)

        let pairingClient = PairingClientFactory.create(logger: pairingLogger, keyValueStorage: keyValueStorage, keychainStorage: keychain, relayClient: relayClient)

        let pushClient = PushClientFactory.create(logger: pushLogger, keyValueStorage: keyValueStorage, keychainStorage: keychain, relayClient: relayClient, pairingClient: pairingClient)
        return (pairingClient, pushClient)
    }

    func makePairingClient(prefix: String) -> PairingClient {
        let keychain = KeychainStorageMock()
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let relayClient = RelayClient(relayHost: InputConfig.relayHost, projectId: InputConfig.projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)

        let pairingClient = PairingClientFactory.create(logger: logger, keyValueStorage: RuntimeKeyValueStorage(), keychainStorage: keychain, relayClient: relayClient)
        return pairingClient
    }

    func testProposePushOnPairing() async {
        let exp = expectation(description: "testProposePushOnPairing")

        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
        (walletPairingClient, walletPushClient) = makeClients(prefix: "🐶 Wallet")

        walletPushClient.proposalPublisher.sink { _ in
            exp.fulfill()
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appPushClient.propose(topic: uri.topic)

        wait(for: [exp], timeout: InputConfig.defaultTimeout)
    }

    func testPing() async {
        let pingExpectation = expectation(description: "expects ping response")

        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
        (walletPairingClient, walletPushClient) = makeClients(prefix: "🐶 Wallet")

        let uri = try! await appPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await walletPairingClient.ping(topic: uri.topic)
        walletPairingClient.pingResponsePublisher
            .sink { topic in
                XCTAssertEqual(topic, uri.topic)
                pingExpectation.fulfill()
            }.store(in: &publishers)
        wait(for: [pingExpectation], timeout: InputConfig.defaultTimeout)
    }
    
    func testResponseErrorForMethodUnregistered() async {
        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
        walletPairingClient = makePairingClient(prefix: "🐶 Wallet")

        let exp = expectation(description: "testProposePushOnPairing")

        appPushClient.responsePublisher.sink { (id, response) in
            XCTAssertEqual(response, .failure(PairError(code: 4444)!))
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appPushClient.propose(topic: uri.topic)

        wait(for: [exp], timeout: InputConfig.defaultTimeout)

    }

    func testDisconnect() {

    }
}

