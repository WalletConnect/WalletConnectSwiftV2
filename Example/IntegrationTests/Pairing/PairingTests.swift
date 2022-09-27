import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
@testable import WalletConnectPairing


final class PairingTests: XCTestCase {

    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appPushClient: PushClient!
    var walletPushClient: PushClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    private let defaultTimeout: TimeInterval = 30

    override func setUp() {
        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
        (walletPairingClient, walletPushClient) = makeClients(prefix: "🐶 Wallet")
    }

    func makeClients(prefix: String) -> (PairingClient, PushClient) {
        let keychain = KeychainStorageMock()
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let projectId = "3ca2919724fbfa5456a25194e369a8b4"
        let relayClient = RelayClient(relayHost: URLConfig.relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)

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

        wait(for: [exp], timeout: defaultTimeout)
    }
}

