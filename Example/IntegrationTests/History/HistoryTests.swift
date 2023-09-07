import Foundation
import Combine
import XCTest
@testable import WalletConnectHistory

final class HistoryTests: XCTestCase {

    var publishers = Set<AnyCancellable>()

    let relayUrl = "wss://relay.walletconnect.com"
    let historyUrl = "https://history.walletconnect.com"

    var relayClient1: RelayClient!
    var relayClient2: RelayClient!

    var historyClient: HistoryNetworkService!

    override func setUp() {
        let keychain1 = KeychainStorageMock()
        let keychain2 = KeychainStorageMock()
        let logger1 = ConsoleLoggerMock()
        let defaults1 = RuntimeKeyValueStorage()
        relayClient1 = makeRelayClient(prefix: "🐄", keychain: keychain1)
        relayClient2 = makeRelayClient(prefix: "🐫", keychain: keychain2)
        historyClient = makeHistoryClient(defaults: defaults1, keychain: keychain1, logger: logger1)
    }

    private func makeRelayClient(prefix: String, keychain: KeychainStorageProtocol) -> RelayClient {
        return RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            logger: ConsoleLogger(prefix: prefix + " [Relay]", loggingLevel: .debug))
    }

    private func makeHistoryClient(defaults: KeyValueStorage, keychain: KeychainStorageProtocol, logger: ConsoleLogging) -> HistoryNetworkService {
        let clientIdStorage = ClientIdStorage(defaults: defaults, keychain: keychain, logger: logger)
        return HistoryNetworkService(clientIdStorage: clientIdStorage)
    }

    func testRegister() async throws {
        let payload = RegisterPayload(tags: ["7000"], relayUrl: relayUrl)

        try await historyClient.registerTags(payload: payload, historyUrl: historyUrl)
    }

    func testGetMessages() async throws {
        let exp = expectation(description: "Test Get Messages")
        let tag = 7000
        let payload = "{}"
        let agreement = AgreementPrivateKey()
        let topic = agreement.publicKey.rawRepresentation.sha256().hex

        relayClient2.messagePublisher.sink { (topic, message, publishedAt) in
            exp.fulfill()
        }.store(in: &publishers)

        try await historyClient.registerTags(
            payload: RegisterPayload(tags: [String(tag)], relayUrl: relayUrl),
            historyUrl: historyUrl)

        try await relayClient2.subscribe(topic: topic)
        try await relayClient1.publish(topic: topic, payload: payload, tag: tag, prompt: false, ttl: 3000)

        wait(for: [exp], timeout: InputConfig.defaultTimeout)

        sleep(5) // History server has a queue

        let messages = try await historyClient.getMessages(
            payload: GetMessagesPayload(
                topic: topic,
                originId: nil,
                messageCount: 200,
                direction: .forward),
            historyUrl: historyUrl)

        XCTAssertEqual(messages.messages, [payload])
    }
}
