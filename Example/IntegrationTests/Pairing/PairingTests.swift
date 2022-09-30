import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectPush
@testable import WalletConnectPairing


final class PairingTests: XCTestCase {

    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appPushClient: PushClient!
    var walletPushClient: PushClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    override func setUp() {
        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
        (walletPairingClient, walletPushClient) = makeClients(prefix: "🐶 Wallet")
    }

    func makeClients(prefix: String) -> (PairingClient, PushClient) {
        let keychain = KeychainStorageMock()
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let relayClient = RelayClient(relayHost: InputConfig.relayHost, projectId: InputConfig.projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)

        let pairingClient = PairingClientFactory.create(logger: logger, keyValueStorage: RuntimeKeyValueStorage(), keychainStorage: keychain, relayClient: relayClient)

        let pushClient = PushClientFactory.create(logger: logger, keyValueStorage: RuntimeKeyValueStorage(), keychainStorage: keychain, relayClient: relayClient, pairingClient: pairingClient)
        return (pairingClient, pushClient)

    }

    func testProposePushOnPairing() async throws {
        let exp = expectation(description: "testProposePushOnPairing") 

        walletPushClient.proposalPublisher.sink { _ in
            exp.fulfill()
        }.store(in: &publishers)

        let uri = try await appPairingClient.create()

        try await walletPairingClient.pair(uri: uri)

        try await appPushClient.propose(topic: uri.topic)

        wait(for: [exp], timeout: InputConfig.defaultTimeout)
    }

    func testPing() async {
        let pingExpectation = expectation(description: "expects ping response")
        let uri = try! await appPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await walletPairingClient.ping(topic: uri.topic)
        walletPairingClient.pingResponsePublisher
            .sink { topic in
                XCTAssertEqual(topic, uri.topic)
                pingExpectation.fulfill()
            }
            .store(in: &publishers)
        wait(for: [pingExpectation], timeout: InputConfig.defaultTimeout)
    }
}

