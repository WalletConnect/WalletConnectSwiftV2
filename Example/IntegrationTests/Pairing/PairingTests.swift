import Foundation
import XCTest
@testable import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectEcho
@testable import Auth
@testable import WalletConnectPairing
@testable import WalletConnectSync
@testable import WalletConnectHistory

final class PairingTests: XCTestCase {

    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appAuthClient: AuthClient!
    var walletAuthClient: AuthClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    func makeClientDependencies(prefix: String) -> (PairingClient, NetworkingInteractor, KeychainStorageProtocol, KeyValueStorage) {
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
            socketFactory: DefaultSocketFactory(),
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
        let clientId = try! networkingClient.getClientId()
        networkingLogger.debug("My client id is: \(clientId)")
        
        return (pairingClient, networkingClient, keychain, keyValueStorage)
    }

    func makeDappClients() {
        let prefix = "🤖 Dapp: "
        let (pairingClient, networkingInteractor, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
        appPairingClient = pairingClient
        
        appAuthClient = AuthClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            projectId: InputConfig.projectId,
            crypto: DefaultCryptoProvider(),
            logger: pushLogger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingInteractor,
            pairingRegisterer: pairingClient,
            iatProvider: IATProviderMock())
    }

    func makeWalletClients() {
        let prefix = "🐶 Wallet: "
        let (pairingClient, networkingInteractor, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
        walletPairingClient = pairingClient
        let historyClient = HistoryClientFactory.create(
            historyUrl: "https://history.walletconnect.com",
            relayUrl: "wss://relay.walletconnect.com",
            keychain: keychain
        )
        appAuthClient = AuthClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            projectId: InputConfig.projectId,
            crypto: DefaultCryptoProvider(),
            logger: pushLogger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingInteractor,
            pairingRegisterer: pairingClient,
            iatProvider: IATProviderMock())
    }

    func makeWalletPairingClient() {
        let prefix = "🐶 Wallet: "
        let (pairingClient, _, _, _) = makeClientDependencies(prefix: prefix)
        walletPairingClient = pairingClient
    }

    override func setUp() {
        makeDappClients()
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

        appAuthClient.authResponsePublisher.sink { (_, response) in
            XCTAssertEqual(response, .failure(AuthError(code: 10001)!))
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appAuthClient.request(RequestParams.stub(), topic: uri.topic)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testDisconnect() {
        // TODO
    }
}
