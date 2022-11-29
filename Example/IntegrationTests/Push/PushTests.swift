import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
@testable import WalletConnectPush
@testable import WalletConnectPairing

final class PushTests: XCTestCase {

    var dappPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var dappPushClient: DappPushClient!
    var walletPushClient: WalletPushClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    func makeClientDependencies(prefix: String) -> (PairingClient, NetworkInteracting, KeychainStorageProtocol, KeyValueStorage) {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let relayLogger = ConsoleLogger(suffix: prefix + " [Relay]", loggingLevel: .debug)
        let pairingLogger = ConsoleLogger(suffix: prefix + " [Pairing]", loggingLevel: .debug)
        let networkingLogger = ConsoleLogger(suffix: prefix + " [Networking]", loggingLevel: .debug)

        let relayClient = RelayClient(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: SocketFactory(),
            logger: relayLogger)

        let networkingClient = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: networkingLogger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage)

        let pairingClient = PairingClientFactory.create(
            logger: pairingLogger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient)


        return (pairingClient, networkingClient, keychain, keyValueStorage)
    }

    func makeDappClients()  {
        let prefix = "🦄 Dapp: "
        let (pairingClient, networkingInteractor, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
        dappPairingClient = pairingClient
        dappPushClient = DappPushClientFactory.create(metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
                                                      logger: pushLogger,
                                                      keyValueStorage: keyValueStorage,
                                                      keychainStorage: keychain,
                                                      networkInteractor: networkingInteractor)
    }

    func makeWalletClients()  {
        let prefix = "🦋 Wallet: "
        let (pairingClient, networkingInteractor, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
        walletPairingClient = pairingClient
        walletPushClient = WalletPushClientFactory.create(logger: pushLogger,
                                                          keyValueStorage: keyValueStorage,
                                                          keychainStorage: keychain,
                                                          networkInteractor: networkingInteractor,
                                                          pairingRegisterer: pairingClient)
    }

    override func setUp() {
        makeDappClients()
        makeWalletClients()
    }

    func testRequestPush() async {
        let expectation = expectation(description: "expects to receive push request")

        let uri = try! await dappPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await dappPushClient.request(account: Account.stub(), topic: uri.topic)

        walletPushClient.requestPublisher.sink { (topic, request) in
            expectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [expectation], timeout: 5)
    }

    func testWalletApprovesPushRequest() async {
        let expectation = expectation(description: "expects dapp to receive successful response")

        let uri = try! await dappPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await dappPushClient.request(account: Account.stub(), topic: uri.topic)

        walletPushClient.requestPublisher.sink { [unowned self] (id, _) in

            Task(priority: .high) { try! await walletPushClient.approve(id: id) }
        }.store(in: &publishers)

        dappPushClient.responsePublisher.sink { (id, result) in
            guard case .success = result else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }.store(in: &publishers)

        wait(for: [expectation], timeout: 5)
    }
}
