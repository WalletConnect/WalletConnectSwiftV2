import Foundation
import Combine
import XCTest
@testable import WalletConnectHistory

final class HistoryTests: XCTestCase {

    var relayClient1: RelayClient!
    var historyClient: HistoryClient!

    override func setUp() {
        let keychain = KeychainStorageMock()
        relayClient1 = makeRelayClient(prefix: "🐄", keychain: keychain)
        historyClient = makeHistoryClient(keychain: keychain)
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
        let payload = RegisterPayload(tags: ["7000"], relayUrl: "wss://relay.walletconnect.com")

        try await historyClient.registerTags(payload: payload, historyUrl: "https://history.walletconnect.com")
    }
}
