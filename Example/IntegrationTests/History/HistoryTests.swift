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

    var historyClient: HistoryClient!

    override func setUp() {
        let keychain1 = KeychainStorageMock()
        let keychain2 = KeychainStorageMock()
        relayClient1 = makeRelayClient(prefix: "🐄", keychain: keychain1)
        relayClient2 = makeRelayClient(prefix: "🐫", keychain: keychain2)
        historyClient = makeHistoryClient(keychain: keychain1)
    }

    private func makeRelayClient(prefix: String, keychain: KeychainStorageProtocol) -> RelayClient {
        return RelayClient(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            logger: ConsoleLogger(suffix: prefix + " [Relay]", loggingLevel: .debug))
    }

    private func makeHistoryClient(keychain: KeychainStorageProtocol) -> HistoryClient {
        let clientIdStorage = ClientIdStorage(keychain: keychain)
        return HistoryClient(clientIdStorage: clientIdStorage)
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
 
        await fulfillment(of: [exp], timeout: InputConfig.defaultTimeout)

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
