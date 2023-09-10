import Foundation
import XCTest
import WalletConnectUtils
import Web3
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectPush
@testable import WalletConnectNotify
@testable import WalletConnectPairing
import WalletConnectIdentity
import WalletConnectSigner

final class NotifyTests: XCTestCase {

    var walletPairingClient: PairingClient!

    var walletNotifyClientA: NotifyClient!

    let gmDappUrl = "https://dev.gm.walletconnect.com/"

    let pk = try! EthereumPrivateKey()

    var privateKey: Data {
        return Data(pk.rawPrivateKey)
    }

    var account: Account {
        return Account("eip155:1:" + pk.address.hex(eip55: true))!
    }

    private var publishers = Set<AnyCancellable>()

    func makeClientDependencies(prefix: String) -> (PairingClient, NetworkInteracting, KeychainStorageProtocol, KeyValueStorage) {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let relayLogger = ConsoleLogger(prefix: prefix + " [Relay]", loggingLevel: .debug)
        let pairingLogger = ConsoleLogger(prefix: prefix + " [Pairing]", loggingLevel: .debug)
        let networkingLogger = ConsoleLogger(prefix: prefix + " [Networking]", loggingLevel: .debug)
        let kmsLogger = ConsoleLogger(prefix: prefix + " [KMS]", loggingLevel: .debug)

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
            keyValueStorage: keyValueStorage,
            kmsLogger: kmsLogger)

        let pairingClient = PairingClientFactory.create(
            logger: pairingLogger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient)

        let clientId = try! networkingClient.getClientId()
        networkingLogger.debug("My client id is: \(clientId)")
        return (pairingClient, networkingClient, keychain, keyValueStorage)
    }

    func makeWalletClient(prefix: String = "🦋 Wallet: ") -> NotifyClient {
        let (pairingClient, networkingInteractor, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let notifyLogger = ConsoleLogger(prefix: prefix + " [Notify]", loggingLevel: .debug)
        walletPairingClient = pairingClient
        let pushClient = PushClientFactory.create(projectId: "",
                                                  pushHost: "echo.walletconnect.com",
                                                  keychainStorage: keychain,
                                                  environment: .sandbox)
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let client = NotifyClientFactory.create(keyserverURL: keyserverURL,
                                                        logger: notifyLogger,
                                                        keyValueStorage: keyValueStorage,
                                                        keychainStorage: keychain,
                                                        groupKeychainStorage: KeychainStorageMock(),
                                                        networkInteractor: networkingInteractor,
                                                        pairingRegisterer: pairingClient,
                                                        pushClient: pushClient,
                                                        crypto: DefaultCryptoProvider())
        return client
    }

    override func setUp() {
        walletNotifyClientA = makeWalletClient()
    }

    func testWalletCreatesSubscription() async {
        let expectation = expectation(description: "expects to create notify subscription")
        let metadata = AppMetadata(name: "GM Dapp", description: "", url: gmDappUrl, icons: [])

        walletNotifyClientA.newSubscriptionPublisher
            .sink { [unowned self] subscription in
                Task(priority: .high) {
                    try! await walletNotifyClientA.deleteSubscription(topic: subscription.topic)
                    expectation.fulfill()
                }
            }.store(in: &publishers)

        try! await walletNotifyClientA.register(account: account, onSign: sign)
        try! await walletNotifyClientA.subscribe(metadata: metadata, account: account, onSign: sign)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testNotifyWatchSubscriptions() async throws {
        let expectation = expectation(description: "expects client B to receive subscription created by client A")
        let metadata = AppMetadata(name: "GM Dapp", description: "", url: gmDappUrl, icons: [])

        let clientB = makeWalletClient(prefix: "👐🏼 Wallet B: ")
        clientB.subscriptionsPublisher.sink { subscriptions in
            Task(priority: .high) {
                if !subscriptions.isEmpty {
                    expectation.fulfill()
                }
            }
        }.store(in: &publishers)

        try! await walletNotifyClientA.register(account: account, onSign: sign)


        try! await walletNotifyClientA.subscribe(metadata: metadata, account: account, onSign: sign)
        sleep(1)
        try! await clientB.register(account: account, onSign: sign)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testNotifySubscriptionChanged() async throws {
        let expectation = expectation(description: "expects client B to receive subscription after both clients are registered and client A creates one")
        expectation.assertForOverFulfill = true
        let metadata = AppMetadata(name: "GM Dapp", description: "", url: gmDappUrl, icons: [])

        let clientB = makeWalletClient(prefix: "👐🏼 Wallet B: ")
        clientB.subscriptionsPublisher.sink { subscriptions in
            Task(priority: .high) {
                if !subscriptions.isEmpty {
                    expectation.fulfill()
                }
            }
        }.store(in: &publishers)

        try! await walletNotifyClientA.register(account: account, onSign: sign)
        try! await clientB.register(account: account, onSign: sign)

        sleep(1)
        try! await walletNotifyClientA.subscribe(metadata: metadata, account: account, onSign: sign)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }
    
    func testWalletCreatesAndUpdatesSubscription() async {
        let expectation = expectation(description: "expects to create and update notify subscription")
        let metadata = AppMetadata(name: "GM Dapp", description: "", url: gmDappUrl, icons: [])
        let updateScope: Set<String> = ["alerts"]
        try! await walletNotifyClientA.register(account: account, onSign: sign)
        try! await walletNotifyClientA.subscribe(metadata: metadata, account: account, onSign: sign)
        walletNotifyClientA.newSubscriptionPublisher
            .sink { [unowned self] subscription in
                Task(priority: .high) {
                    try! await walletNotifyClientA.update(topic: subscription.topic, scope: updateScope)
                }
            }
            .store(in: &publishers)

        walletNotifyClientA.updateSubscriptionPublisher
            .sink { [unowned self] subscription in
                let updatedScope = Set(subscription.scope.filter{ $0.value.enabled == true }.keys)
                XCTAssertEqual(updatedScope, updateScope)
                Task(priority: .high) {
                    try! await walletNotifyClientA.deleteSubscription(topic: subscription.topic)
                    expectation.fulfill()
                }
            }.store(in: &publishers)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testNotifyServerSubscribeAndNotifies() async throws {
        let subscribeExpectation = expectation(description: "creates notify subscription")
        let messageExpectation = expectation(description: "receives a notify message")
        let notifyMessage = NotifyMessage.stub()

        let metadata = AppMetadata(name: "GM Dapp", description: "", url: gmDappUrl, icons: [])
        try! await walletNotifyClientA.register(account: account, onSign: sign)
        try! await walletNotifyClientA.subscribe(metadata: metadata, account: account, onSign: sign)

        walletNotifyClientA.newSubscriptionPublisher
            .sink { subscription in
                let notifier = Publisher()
                Task(priority: .high) {
                    try await notifier.notify(topic: subscription.topic, account: subscription.account, message: notifyMessage)
                    subscribeExpectation.fulfill()
                }
            }.store(in: &publishers)

        walletNotifyClientA.notifyMessagePublisher
            .sink { [unowned self] notifyMessageRecord in
                XCTAssertEqual(notifyMessage, notifyMessageRecord.message)

                Task(priority: .high) {
                    try await walletNotifyClientA.deleteSubscription(topic: notifyMessageRecord.topic)
                    messageExpectation.fulfill()
                }
        }.store(in: &publishers)

        wait(for: [subscribeExpectation, messageExpectation], timeout: InputConfig.defaultTimeout)
    }

}


private extension NotifyTests {
    func sign(_ message: String) -> SigningResult {
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create(projectId: InputConfig.projectId)
        return .signed(try! signer.sign(message: message, privateKey: privateKey, type: .eip191))
    }
}
