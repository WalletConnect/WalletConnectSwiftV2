
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
import WalletConnectIdentity
import WalletConnectSigner

final class NotifyTests: XCTestCase {

    var walletNotifyClientA: NotifyClient!

    let gmDappDomain = InputConfig.gmDappHost

    var pk: EthereumPrivateKey!

    var privateKey: Data {
        return Data(pk.rawPrivateKey)
    }

    var account: Account {
        return Account("eip155:1:" + pk.address.hex(eip55: true))!
    }

    private var publishers = Set<AnyCancellable>()

    func makeClientDependencies(prefix: String) -> (NetworkInteracting, KeychainStorageProtocol, KeyValueStorage) {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let relayLogger = ConsoleLogger(prefix: prefix + " [Relay]", loggingLevel: .debug)
        let networkingLogger = ConsoleLogger(prefix: prefix + " [Networking]", loggingLevel: .debug)
        let kmsLogger = ConsoleLogger(prefix: prefix + " [KMS]", loggingLevel: .debug)

        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            networkMonitor: NetworkMonitor(),
            logger: relayLogger)

        let networkingClient = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: networkingLogger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage,
            kmsLogger: kmsLogger)

        let clientId = try! networkingClient.getClientId()
        networkingLogger.debug("My client id is: \(clientId)")
        return (networkingClient, keychain, keyValueStorage)
    }

    func makeWalletClient(prefix: String = "🦋 Wallet: ") -> NotifyClient {
        let (networkingInteractor, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let notifyLogger = ConsoleLogger(prefix: prefix + " [Notify]", loggingLevel: .debug)
        let pushClient = PushClientFactory.create(projectId: "",
                                                  pushHost: "echo.walletconnect.com",
                                                  keyValueStorage: keyValueStorage,
                                                  keychainStorage: keychain,
                                                  environment: .sandbox)
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let sqlite = try! MemorySqlite()
        // Note:- prod project_id do not exists on staging, we can use gmDappProjectId
        let client = NotifyClientFactory.create(projectId: InputConfig.gmDappProjectId,
                                                keyserverURL: keyserverURL, 
                                                sqlite: sqlite,
                                                logger: notifyLogger,
                                                keychainStorage: keychain,
                                                groupKeychainStorage: KeychainStorageMock(),
                                                networkInteractor: networkingInteractor,
                                                pushClient: pushClient,
                                                crypto: DefaultCryptoProvider(),
                                                notifyHost: InputConfig.notifyHost, 
                                                explorerHost: InputConfig.explorerHost)
        return client
    }

    override func setUp() {
        pk = try! EthereumPrivateKey()
        walletNotifyClientA = makeWalletClient()
        publishers.removeAll()
    }

    func testWalletCreatesSubscription() async throws {
        let expectation = expectation(description: "expects to create notify subscription")
        expectation.assertForOverFulfill = false

        var subscription: NotifySubscription?

        walletNotifyClientA.subscriptionsPublisher
            .sink { subscriptions in
                subscription = subscriptions.first
                expectation.fulfill()
            }.store(in: &publishers)

        try await walletNotifyClientA.register(account: account, domain: gmDappDomain, onSign: sign)
        try await walletNotifyClientA.subscribe(appDomain: gmDappDomain, account: account)

        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)

        if let subscription {
            try await walletNotifyClientA.deleteSubscription(topic: subscription.topic)
        }
    }

    func testNotifyWatchSubscriptions() async throws {
        let expectation = expectation(description: "expects client B to receive subscription created by client A")
        expectation.assertForOverFulfill = false

        var subscription: NotifySubscription?

        let clientB = makeWalletClient(prefix: "👐🏼 Wallet B: ")
        clientB.subscriptionsPublisher.sink { subscriptions in
            subscription = subscriptions.first
            expectation.fulfill()
        }.store(in: &publishers)

        try! await walletNotifyClientA.register(account: account, domain: gmDappDomain, onSign: sign)
        try! await walletNotifyClientA.subscribe(appDomain: gmDappDomain, account: account)
        try! await clientB.register(account: account, domain: gmDappDomain, onSign: sign)

        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)

        if let subscription {
            try await clientB.deleteSubscription(topic: subscription.topic)
        }
    }

    func testNotifySubscriptionChanged() async throws {
        let expectation = expectation(description: "expects client B to receive subscription after both clients are registered and client A creates one")
        expectation.assertForOverFulfill = false

        var subscription: NotifySubscription?

        let clientB = makeWalletClient(prefix: "👐🏼 Wallet B: ")
        clientB.subscriptionsPublisher.sink { subscriptions in
            subscription = subscriptions.first
            expectation.fulfill()
        }.store(in: &publishers)

        try! await walletNotifyClientA.register(account: account, domain: gmDappDomain, onSign: sign)
        try! await clientB.register(account: account, domain: gmDappDomain, onSign: sign)
        try! await walletNotifyClientA.subscribe(appDomain: gmDappDomain, account: account)

        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)

        if let subscription {
            try await clientB.deleteSubscription(topic: subscription.topic)
        }
    }

    func testWalletCreatesAndUpdatesSubscription() async throws {
        let created = expectation(description: "Subscription created")

        let updated = expectation(description: "Subscription Updated")

        var isCreated = false
        var isUpdated = false
        var subscription: NotifySubscription!

        walletNotifyClientA.subscriptionsPublisher
            .sink { subscriptions in
                subscription = subscriptions.first

                if !isCreated {
                    isCreated = true
                    created.fulfill()
                } else if !isUpdated {
                    isUpdated = true
                    updated.fulfill()
                }
            }.store(in: &publishers)

        try await walletNotifyClientA.register(account: account, domain: gmDappDomain, onSign: sign)
        try await walletNotifyClientA.subscribe(appDomain: gmDappDomain, account: account)

        await fulfillment(of: [created], timeout: InputConfig.defaultTimeout)

        try await walletNotifyClientA.update(topic: subscription.topic, scope: [])

        await fulfillment(of: [updated], timeout: InputConfig.defaultTimeout)

        let updatedScope = subscription.scope.filter { $0.value.enabled == true }
        XCTAssertTrue(updatedScope.isEmpty)

        try await walletNotifyClientA.deleteSubscription(topic: subscription.topic)
    }

    func testNotifyServerSubscribeAndNotifies() async throws {
        let subscribeExpectation = expectation(description: "creates notify subscription")
        let messageExpectation = expectation(description: "receives a notify message")

        var notifyMessage: NotifyMessage!
        var notifyMessageRecord: NotifyMessageRecord?

        var didNotify = false
        walletNotifyClientA.subscriptionsPublisher
            .sink { subscriptions in
                guard
                    let subscription = subscriptions.first,
                    let scope = subscription.scope.keys.first
                else { return }

                let notifier = Publisher()
                if !didNotify {
                    didNotify = true

                    let message = NotifyMessage.stub(type: scope)
                    notifyMessage = message

                    Task(priority: .high) {
                        try await notifier.notify(topic: subscription.topic, account: subscription.account, message: message)
                        subscribeExpectation.fulfill()
                    }
                }
            }.store(in: &publishers)

        walletNotifyClientA.messagesPublisher
            .sink { messages in
                guard let newNotifyMessageRecord = messages.first else { return }
                // ID's is not equal because server generates a new one
                XCTAssertEqual(newNotifyMessageRecord.message.title, notifyMessage.title)
                XCTAssertEqual(newNotifyMessageRecord.message.body, notifyMessage.body)
                XCTAssertEqual(newNotifyMessageRecord.message.icon, notifyMessage.icon)
                XCTAssertEqual(newNotifyMessageRecord.message.type, notifyMessage.type)
                notifyMessageRecord = newNotifyMessageRecord
                messageExpectation.fulfill()
        }.store(in: &publishers)

        try! await walletNotifyClientA.register(account: account, domain: gmDappDomain, onSign: sign)
        try! await walletNotifyClientA.subscribe(appDomain: gmDappDomain, account: account)

        await fulfillment(of: [subscribeExpectation, messageExpectation], timeout: InputConfig.defaultTimeout)

        if let notifyMessageRecord {
            try await walletNotifyClientA.deleteSubscription(topic: notifyMessageRecord.topic)
        }
    }

    func testFetchHistory() async throws {
        let subscribeExpectation = expectation(description: "fetch notify subscription")
        let account = Account("eip155:1:0x622b17376F76d72C43527a917f59273247A917b4")!

        var subscription: NotifySubscription!
        walletNotifyClientA.subscriptionsPublisher
            .sink { subscriptions in
                subscription = subscriptions.first
                subscribeExpectation.fulfill()
            }.store(in: &publishers)

        try await walletNotifyClientA.register(account: account, domain: gmDappDomain) { message in
            let privateKey = Data(hex: "c3ff8a0ae33ac5d58e515055c5870fa2f220d070997bd6fd77a5f2c148528ff0")
            let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
            return try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
        }

        await fulfillment(of: [subscribeExpectation], timeout: InputConfig.defaultTimeout)

        let hasMore = try await walletNotifyClientA.fetchHistory(subscription: subscription, after: nil, limit: 20)
        XCTAssertTrue(hasMore)
        XCTAssertTrue(walletNotifyClientA.getMessageHistory(topic: subscription.topic).count == 20)
    }
}


private extension NotifyTests {
    func sign(_ message: String) -> CacaoSignature {
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
        return try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
    }
}

private extension NotifyClient {

    func register(account: Account, domain: String, onSign: @escaping (String) -> CacaoSignature) async throws {
        let params = try await prepareRegistration(account: account, domain: "https://\(domain)")
        let signature = onSign(params.message)
        try await register(params: params, signature: signature)
    }
}

