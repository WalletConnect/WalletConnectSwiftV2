import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectPairing


final class PairingTests: XCTestCase {
    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appPushClient: PushClient!
    var walletPushClient: PushClient!

    private var publishers = [AnyCancellable]()

    override func setUp() {
        (appPairingClient, appPushClient) = makeClients(prefix: "👻 App")
        (walletPairingClient, walletPushClient) = makeClients(prefix: "🤑 Wallet")

        let expectation = expectation(description: "Wait Clients Connected")
        expectation.expectedFulfillmentCount = 2

        appPairingClient.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                expectation.fulfill()
            }
        }.store(in: &publishers)

        walletPairingClient.socketConnectionStatusPublisher.sink { status in
            if status == .connected {
                expectation.fulfill()
            }
        }.store(in: &publishers)

        wait(for: [expectation], timeout: 5)
    }

    func makeClients(prefix: String) -> (PairingClient, PushClient) {
        let keychain = KeychainStorageMock()
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let projectId = "3ca2919724fbfa5456a25194e369a8b4"
        let relayClient = RelayClient(relayHost: URLConfig.relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)

        let pairingClient = PairingClientFactory.create(logger: logger, keyValueStorage: RuntimeKeyValueStorage(), keychainStorage: keychain, relayClient: relayClient)

        let pushClient = PushClientFactory.create(logger: logger, keyValueStorage: RuntimeKeyValueStorage(), keychainStorage: keychain, relayClient: relayClient)
        return (pairingClient, pushClient)

    }

    func testProposePushOnPairing() async {
        let exp = expectation(description: "")

        walletPushClient.proposalPublisher.sink { _ in
            exp.fulfill()
        }.store(in: &publishers)

        appPairingClient.configureProtocols(with: [appPushClient])

        walletPairingClient.configureProtocols(with: [walletPushClient])

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appPushClient.propose(topic: uri.topic)

        wait(for: [exp], timeout: 2)

    }

}

