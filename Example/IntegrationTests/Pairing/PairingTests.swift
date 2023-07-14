import Foundation
import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectEcho
@testable import WalletConnectPush
@testable import WalletConnectPairing
@testable import WalletConnectSync
@testable import WalletConnectHistory

final class PairingTests: XCTestCase {

    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appPushClient: DappPushClient!
    var walletPushClient: WalletPushClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    func makeClientDependencies(prefix: String) -> (PairingClient, NetworkInteracting, SyncClient, KeychainStorageProtocol, KeyValueStorage) {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let relayLogger = ConsoleLogger(suffix: prefix + " [Relay]", loggingLevel: .debug)
        let pairingLogger = ConsoleLogger(suffix: prefix + " [Pairing]", loggingLevel: .debug)
        let networkingLogger = ConsoleLogger(suffix: prefix + " [Networking]", loggingLevel: .debug)

        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
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

        let syncClient = SyncClientFactory.create(networkInteractor: networkingClient, bip44: DefaultBIP44Provider(), keychain: keychain)

        let clientId = try! networkingClient.getClientId()
        networkingLogger.debug("My client id is: \(clientId)")
        
        return (pairingClient, networkingClient, syncClient, keychain, keyValueStorage)
    }

    func makeDappClients() {
        let prefix = "🤖 Dapp: "
        let (pairingClient, networkingInteractor, syncClient, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
        appPairingClient = pairingClient
        appPushClient = DappPushClientFactory.create(metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
                                                     logger: pushLogger,
                                                     keyValueStorage: keyValueStorage,
                                                     keychainStorage: keychain,
                                                     groupKeychainStorage: KeychainStorageMock(),
                                                     networkInteractor: networkingInteractor,
                                                     syncClient: syncClient)
    }

    func makeWalletClients() {
        let prefix = "🐶 Wallet: "
        let (pairingClient, networkingInteractor, syncClient, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
        walletPairingClient = pairingClient
        let echoClient = EchoClientFactory.create(projectId: "",
                                                  echoHost: "echo.walletconnect.com",
                                                  keychainStorage: keychain,
                                                  environment: .sandbox)
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let historyClient = HistoryClientFactory.create(
            historyUrl: "https://history.walletconnect.com",
            relayUrl: "wss://relay.walletconnect.com",
            keychain: keychain
        )
        walletPushClient = WalletPushClientFactory.create(keyserverURL: keyserverURL,
                                                          logger: pushLogger,
                                                          keyValueStorage: keyValueStorage,
                                                          keychainStorage: keychain,
                                                          groupKeychainStorage: KeychainStorageMock(),
                                                          networkInteractor: networkingInteractor,
                                                          pairingRegisterer: pairingClient,
                                                          echoClient: echoClient,
                                                          syncClient: syncClient,
                                                          historyClient: historyClient)
    }

    func makeWalletPairingClient() {
        let prefix = "🐶 Wallet: "
        let (pairingClient, _, _, _, _) = makeClientDependencies(prefix: prefix)
        walletPairingClient = pairingClient
    }

    override func setUp() {
        makeDappClients()
    }

    func testProposePushOnPairing() async {
        makeWalletClients()
        let expectation = expectation(description: "propose push on pairing")

        walletPushClient.requestPublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appPushClient.propose(account: Account.stub(), topic: uri.topic)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testPing() async {
        let expectation = expectation(description: "expects ping response")
        makeWalletClients()
        let uri = try! await appPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await walletPairingClient.ping(topic: uri.topic)
        walletPairingClient.pingResponsePublisher
            .sink { topic in
                XCTAssertEqual(topic, uri.topic)
                expectation.fulfill()
            }.store(in: &publishers)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testResponseErrorForMethodUnregistered() async {
        makeWalletPairingClient()
        let expectation = expectation(description: "wallet responds unsupported method for unregistered method")

        appPushClient.proposalResponsePublisher.sink { (response) in
            XCTAssertEqual(response, .failure(PushError(code: 10001)!))
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appPushClient.propose(account: Account.stub(), topic: uri.topic)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testDisconnect() {
        // TODO
    }
}
