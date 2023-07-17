import Foundation
import XCTest
import WalletConnectUtils
import Web3
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectEcho
@testable import WalletConnectPush
@testable import WalletConnectPairing
@testable import WalletConnectSync
@testable import WalletConnectHistory
import WalletConnectIdentity
import WalletConnectSigner

final class PushTests: XCTestCase {

    var walletPairingClient: PairingClient!

    var walletPushClient: WalletPushClient!

    var pairingStorage: PairingStorage!

    let pk = try! EthereumPrivateKey()

    var privateKey: Data {
        return Data(pk.rawPrivateKey)
    }

    var account: Account {
        return Account("eip155:1:" + pk.address.hex(eip55: true))!
    }

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
            keyValueStorage: keyValueStorage,
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

        let syncClient = SyncClientFactory.create(networkInteractor: networkingClient, bip44: DefaultBIP44Provider(), keychain: keychain)

        let clientId = try! networkingClient.getClientId()
        networkingLogger.debug("My client id is: \(clientId)")
        return (pairingClient, networkingClient, syncClient, keychain, keyValueStorage)
    }

    func makeWalletClients() {
        let prefix = "🦋 Wallet: "
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

    override func setUp() {
        makeWalletClients()
    }

    func testWalletCreatesSubscription() async {
        let expectation = expectation(description: "expects to create push subscription")
        let metadata = AppMetadata(name: "GM Dapp", description: "", url: "https://gm-dapp-xi.vercel.app/", icons: [])
        try! await walletPushClient.enableSync(account: account, onSign: sign)
        try! await walletPushClient.subscribe(metadata: metadata, account: account, onSign: sign)
        walletPushClient.subscriptionsPublisher
            .first()
            .sink { [unowned self] subscriptions in
                XCTAssertNotNil(subscriptions.first)
                Task { try! await walletPushClient.deleteSubscription(topic: subscriptions.first!.topic) }
                expectation.fulfill()
            }.store(in: &publishers)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }
    
    func testWalletCreatesAndUpdatesSubscription() async {
        let expectation = expectation(description: "expects to create and update push subscription")
        let metadata = AppMetadata(name: "GM Dapp", description: "", url: "https://gm-dapp-xi.vercel.app/", icons: [])
        let updateScope: Set<String> = ["alerts"]
        try! await walletPushClient.enableSync(account: account, onSign: sign)
        try! await walletPushClient.subscribe(metadata: metadata, account: account, onSign: sign)
        walletPushClient.subscriptionsPublisher
            .first()
            .sink { [unowned self] subscriptions in
                sleep(1)
                Task { try! await walletPushClient.update(topic: subscriptions.first!.topic, scope: updateScope) }
            }
            .store(in: &publishers)

        walletPushClient.updateSubscriptionPublisher
            .sink { [unowned self] result in
                guard case .success(let subscription) = result else { XCTFail(); return }
                let updatedScope = Set(subscription.scope.filter{ $0.value.enabled == true }.keys)
                XCTAssertEqual(updatedScope, updateScope)
                Task { try! await walletPushClient.deleteSubscription(topic: subscription.topic) }
                expectation.fulfill()
            }.store(in: &publishers)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testNotifyServerSubscribeAndNotifies() async throws {
        let subscribeExpectation = expectation(description: "creates push subscription")
        let messageExpectation = expectation(description: "receives a push message")
        let pushMessage = PushMessage.stub()

        let metadata = AppMetadata(name: "GM Dapp", description: "", url: "https://gm-dapp-xi.vercel.app/", icons: [])
        try! await walletPushClient.enableSync(account: account, onSign: sign)
        try! await walletPushClient.subscribe(metadata: metadata, account: account, onSign: sign)
        var subscription: PushSubscription!
        walletPushClient.subscriptionsPublisher
            .first()
            .sink { subscriptions in
                XCTAssertNotNil(subscriptions.first)
                subscribeExpectation.fulfill()
                subscription = subscriptions.first!
                let notifier = Publisher()
                sleep(1)
                Task(priority: .high) { try await notifier.notify(topic: subscriptions.first!.topic, account: subscriptions.first!.account, message: pushMessage) }
            }.store(in: &publishers)
        walletPushClient.pushMessagePublisher
            .sink { pushMessageRecord in
                XCTAssertEqual(pushMessage, pushMessageRecord.message)
                messageExpectation.fulfill()
        }.store(in: &publishers)

        wait(for: [subscribeExpectation, messageExpectation], timeout: InputConfig.defaultTimeout)
        try await walletPushClient.deleteSubscription(topic: subscription.topic)
    }

}


private extension PushTests {
    func sign(_ message: String) -> SigningResult {
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        return .signed(try! signer.sign(message: message, privateKey: privateKey, type: .eip191))
    }
}
