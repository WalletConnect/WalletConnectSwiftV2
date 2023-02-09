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

        return (pairingClient, networkingClient, keychain, keyValueStorage)
    }

    func makeDappClients() {
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

    func makeWalletClients() {
        let prefix = "🦋 Wallet: "
        let (pairingClient, networkingInteractor, keychain, keyValueStorage) = makeClientDependencies(prefix: prefix)
        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
        walletPairingClient = pairingClient
        let echoClient = EchoClientFactory.create(projectId: "", clientId: "", echoHost: "echo.walletconnect.com", environment: .sandbox)
        walletPushClient = WalletPushClientFactory.create(logger: pushLogger,
                                                          keyValueStorage: keyValueStorage,
                                                          keychainStorage: keychain,
                                                          groupKeychainStorage: KeychainStorageMock(),
                                                          networkInteractor: networkingInteractor,
                                                          pairingRegisterer: pairingClient,
                                                          echoClient: echoClient)
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

        walletPushClient.requestPublisher.sink { (_, _, _) in
            expectation.fulfill()
        }
        .store(in: &publishers)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testWalletApprovesPushRequest() async {
        let expectation = expectation(description: "expects dapp to receive successful response")

        let uri = try! await dappPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await dappPushClient.request(account: Account.stub(), topic: uri.topic)

        walletPushClient.requestPublisher.sink { [unowned self] (id, _, _) in

            Task(priority: .high) { try! await walletPushClient.approve(id: id) }
        }.store(in: &publishers)

        dappPushClient.responsePublisher.sink { (_, result) in
            guard case .success = result else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }.store(in: &publishers)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testWalletRejectsPushRequest() async {
        let expectation = expectation(description: "expects dapp to receive error response")

        let uri = try! await dappPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await dappPushClient.request(account: Account.stub(), topic: uri.topic)

        walletPushClient.requestPublisher.sink { [unowned self] (id, _, _) in

            Task(priority: .high) { try! await walletPushClient.reject(id: id) }
        }.store(in: &publishers)

        dappPushClient.responsePublisher.sink { (_, result) in
            guard case .failure = result else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }.store(in: &publishers)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testDappSendsPushMessage() async {
        let expectation = expectation(description: "expects wallet to receive push message")
        let pushMessage = PushMessage.stub()
        var pushSubscription: PushSubscription!
        let uri = try! await dappPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await dappPushClient.request(account: Account.stub(), topic: uri.topic)

        walletPushClient.requestPublisher.sink { [unowned self] (id, _, _) in
            Task(priority: .high) { try! await walletPushClient.approve(id: id) }
        }.store(in: &publishers)

        dappPushClient.responsePublisher.sink { [unowned self] (_, result) in
            guard case .success(let subscription) = result else {
                XCTFail()
                return
            }
            pushSubscription = subscription
            Task(priority: .userInitiated) { try! await dappPushClient.notify(topic: subscription.topic, message: pushMessage) }
        }.store(in: &publishers)

        walletPushClient.pushMessagePublisher.sink { [unowned self] receivedPushMessageRecord in
            let messageHistory = walletPushClient.getMessageHistory(topic: pushSubscription.topic)
            XCTAssertEqual(pushMessage, receivedPushMessageRecord.message)
            XCTAssertTrue(messageHistory.contains(receivedPushMessageRecord))
            expectation.fulfill()
        }.store(in: &publishers)


        wait(for: [expectation], timeout: InputConfig.defaultTimeout)

    }

    func testWalletDeletePushSubscription() async {
        let expectation = expectation(description: "expects to delete push subscription")
        let uri = try! await dappPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await dappPushClient.request(account: Account.stub(), topic: uri.topic)
        var subscriptionTopic: String!

        walletPushClient.requestPublisher.sink { [unowned self] (id, _, _) in
            Task(priority: .high) { try! await walletPushClient.approve(id: id) }
        }.store(in: &publishers)

        dappPushClient.responsePublisher.sink { [unowned self] (_, result) in
            guard case .success(let subscription) = result else {
                XCTFail()
                return
            }
            subscriptionTopic = subscription.topic
            Task(priority: .userInitiated) { try! await walletPushClient.deleteSubscription(topic: subscription.topic)}
        }.store(in: &publishers)

        dappPushClient.deleteSubscriptionPublisher.sink { topic in
            XCTAssertEqual(subscriptionTopic, topic)
            expectation.fulfill()
        }.store(in: &publishers)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testDappDeletePushSubscription() async {
        let expectation = expectation(description: "expects to delete push subscription")
        let uri = try! await dappPairingClient.create()
        try! await walletPairingClient.pair(uri: uri)
        try! await dappPushClient.request(account: Account.stub(), topic: uri.topic)
        var subscriptionTopic: String!

        walletPushClient.requestPublisher.sink { [unowned self] (id, _, _) in
            Task(priority: .high) { try! await walletPushClient.approve(id: id) }
        }.store(in: &publishers)

        dappPushClient.responsePublisher.sink { [unowned self] (_, result) in
            guard case .success(let subscription) = result else {
                XCTFail()
                return
            }
            subscriptionTopic = subscription.topic
            Task(priority: .userInitiated) { try! await dappPushClient.delete(topic: subscription.topic)}
        }.store(in: &publishers)

        walletPushClient.deleteSubscriptionPublisher.sink { topic in
            XCTAssertEqual(subscriptionTopic, topic)
            expectation.fulfill()
        }.store(in: &publishers)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }
}
