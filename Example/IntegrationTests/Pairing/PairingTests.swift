import Foundation
import XCTest
@testable import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
@testable import WalletConnectPairing
import WalletConnectSign

final class PairingTests: XCTestCase {

    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    func makeClient(prefix: String, includeSign: Bool = true) -> PairingClient {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let logger = ConsoleLogger(prefix: prefix, loggingLevel: .debug)

        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            networkMonitor: NetworkMonitor(),
            logger: logger)

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


        return pairingClient
    }

    override func setUp() {
        appPairingClient = makeClient(prefix: "🤖 Dapp: ")
        walletPairingClient = makeClient(prefix: "🐶 Wallet: ", includeSign: false)
    }

    func testPing() async {
        let expectation = expectation(description: "expects ping response")
        let uri = try! await appPairingClient.create()
        try? await walletPairingClient.pair(uri: uri)
        try! await walletPairingClient.ping(topic: uri.topic)
        walletPairingClient.pingResponsePublisher
            .sink { topic in
                XCTAssertEqual(topic, uri.topic)
                expectation.fulfill()
            }.store(in: &publishers)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testDisconnect() async {

        let expectation = expectation(description: "wallet disconnected pairing")


        walletPairingClient.pairingDeletePublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try? await walletPairingClient.pair(uri: uri)

        try! await appPairingClient.disconnect(topic: uri.topic)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }
}
