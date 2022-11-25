//import Foundation
//import XCTest
//import WalletConnectUtils
//@testable import WalletConnectKMS
//import WalletConnectRelay
//import Combine
//import WalletConnectNetworking
//@testable import WalletConnectPush
//@testable import WalletConnectPairing
//
//final class PairingTests: XCTestCase {
//
//    var appPairingClient: PairingClient!
//    var walletPairingClient: PairingClient!
//
//    var appPushClient: PushClient!
//    var walletPushClient: PushClient!
//
//    var pairingStorage: PairingStorage!
//
//    private var publishers = [AnyCancellable]()
//
//    func makeClients(prefix: String) -> (PairingClient, PushClient) {
//        let keychain = KeychainStorageMock()
//        let keyValueStorage = RuntimeKeyValueStorage()
//
//        let relayLogger = ConsoleLogger(suffix: prefix + " [Relay]", loggingLevel: .debug)
//        let pairingLogger = ConsoleLogger(suffix: prefix + " [Pairing]", loggingLevel: .debug)
//        let pushLogger = ConsoleLogger(suffix: prefix + " [Push]", loggingLevel: .debug)
//        let networkingLogger = ConsoleLogger(suffix: prefix + " [Networking]", loggingLevel: .debug)
//
//        let relayClient = RelayClient(
//            relayHost: InputConfig.relayHost,
//            projectId: InputConfig.projectId,
//            keyValueStorage: RuntimeKeyValueStorage(),
//            keychainStorage: keychain,
//            socketFactory: SocketFactory(),
//            logger: relayLogger)
//
//        let networkingClient = NetworkingClientFactory.create(
//            relayClient: relayClient,
//            logger: networkingLogger,
//            keychainStorage: keychain,
//            keyValueStorage: keyValueStorage)
//
//        let pairingClient = PairingClientFactory.create(
//            logger: pairingLogger,
//            keyValueStorage: keyValueStorage,
//            keychainStorage: keychain,
//            networkingClient: networkingClient)
//
//        let pushClient = PushClientFactory.create(
//            logger: pushLogger,
//            keyValueStorage: keyValueStorage,
//            keychainStorage: keychain,
//            networkInteractor: networkingClient,
//            pairingRegisterer: pairingClient)
//
//        return (pairingClient, pushClient)
//    }
//
//    func makePairingClient(prefix: String) -> PairingClient {
//        let keychain = KeychainStorageMock()
//        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
//        let keyValueStorage = RuntimeKeyValueStorage()
//
//        let relayClient = RelayClient(
//            relayHost: InputConfig.relayHost,
//            projectId: InputConfig.projectId,
//            keychainStorage: keychain,
//            socketFactory: SocketFactory(),
//            logger: logger)
//
//        let networkingClient = NetworkingClientFactory.create(
//            relayClient: relayClient,
//            logger: logger,
//            keychainStorage: keychain,
//            keyValueStorage: keyValueStorage)
//
//        let pairingClient = PairingClientFactory.create(
//            logger: logger,
//            keyValueStorage: keyValueStorage,
//            keychainStorage: keychain,
//            networkingClient: networkingClient)
//
//        return pairingClient
//    }
//
//    func testProposePushOnPairing() async {
//        let expectation = expectation(description: "propose push on pairing")
//
//        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
//        (walletPairingClient, walletPushClient) = makeClients(prefix: "🐶 Wallet")
//
//        walletPushClient.proposalPublisher.sink { _ in
//            expectation.fulfill()
//        }.store(in: &publishers)
//
//        let uri = try! await appPairingClient.create()
//
//        try! await walletPairingClient.pair(uri: uri)
//
//        try! await appPushClient.propose(topic: uri.topic)
//
//        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
//    }
//
//    func testPing() async {
//        let expectation = expectation(description: "expects ping response")
//
//        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
//        (walletPairingClient, walletPushClient) = makeClients(prefix: "🐶 Wallet")
//
//        let uri = try! await appPairingClient.create()
//        try! await walletPairingClient.pair(uri: uri)
//        try! await walletPairingClient.ping(topic: uri.topic)
//        walletPairingClient.pingResponsePublisher
//            .sink { topic in
//                XCTAssertEqual(topic, uri.topic)
//                expectation.fulfill()
//            }.store(in: &publishers)
//        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
//    }
//
//    func testResponseErrorForMethodUnregistered() async {
//        (appPairingClient, appPushClient) = makeClients(prefix: "🤖 App")
//        walletPairingClient = makePairingClient(prefix: "🐶 Wallet")
//
//        let expectation = expectation(description: "wallet responds unsupported method for unregistered method")
//
//        appPushClient.responsePublisher.sink { (_, response) in
//            XCTAssertEqual(response, .failure(WalletConnectPairing.PairError(code: 10001)!))
//            expectation.fulfill()
//        }.store(in: &publishers)
//
//        let uri = try! await appPairingClient.create()
//
//        try! await walletPairingClient.pair(uri: uri)
//
//        try! await appPushClient.propose(topic: uri.topic)
//
//        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
//
//    }
//
//    func testDisconnect() {
//        // TODO
//    }
//}
