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

    private var publishers = [AnyCancellable]()

    override func setUp() {
        appPairingClient = makeClient(prefix: "👻 App")
        walletPairingClient = makeClient(prefix: "🤑 Wallet")

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


    func makeClient(prefix: String) -> PairingClient {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let projectId = "3ca2919724fbfa5456a25194e369a8b4"
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: URLConfig.relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)

        let pairingClient = PairingClientFactory.create(logger: logger, keyValueStorage: RuntimeKeyValueStorage(), keychainStorage: keychain, relayClient: relayClient)
        return pairingClient
    }

    func makePushClient(suffix: String) -> PushClient {
        let logger = ConsoleLogger(suffix: suffix, loggingLevel: .debug)
        let projectId = "3ca2919724fbfa5456a25194e369a8b4"
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(relayHost: URLConfig.relayHost, projectId: projectId, keychainStorage: keychain, socketFactory: SocketFactory(), logger: logger)
        return PushClientFactory.create(logger: logger, keyValueStorage: RuntimeKeyValueStorage(), keychainStorage: keychain, relayClient: relayClient)
    }

    func testProposePushOnPairing() async {
        let exp = expectation(description: "")
        
        let appPushClient = makePushClient(suffix: "👻 App")
        let walletPushClient = makePushClient(suffix: "🤑 Wallet")

        walletPushClient.proposalPublisher.sink { _ in
            exp.fulfill()
        }.store(in: &publishers)

        appPairingClient.configure(with: [appPushClient])

        walletPairingClient.configure(with: [walletPushClient])

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appPushClient.propose(topic: uri.topic)



        wait(for: [exp], timeout: 2)

    }

}

