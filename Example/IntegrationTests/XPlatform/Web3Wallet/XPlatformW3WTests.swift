import Foundation
import XCTest
import Combine
@testable import Web3Wallet
@testable import Auth
@testable import WalletConnectSign
@testable import WalletConnectPush

final class XPlatformW3WTests: XCTestCase {
    var w3wClient: Web3WalletClient!
    var javaScriptAutoTestsAPI: JavaScriptAutoTestsAPI!
    private var publishers = [AnyCancellable]()

    override func setUp() {
        makeClient()
        javaScriptAutoTestsAPI = JavaScriptAutoTestsAPI()
    }

    func makeClient() {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let relayLogger = ConsoleLogger(prefix: "🚄" + " [Relay]", loggingLevel: .debug)
        let pairingLogger = ConsoleLogger(prefix: "👩‍❤️‍💋‍👩" + " [Pairing]", loggingLevel: .debug)
        let networkingLogger = ConsoleLogger(prefix: "🕸️" + " [Networking]", loggingLevel: .debug)
        let authLogger = ConsoleLogger(prefix: "🪪", loggingLevel: .debug)

        let signLogger = ConsoleLogger(prefix: "✍🏿", loggingLevel: .debug)

        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            logger: relayLogger
        )

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

        let signClient = SignClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            logger: signLogger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            pairingClient: pairingClient,
            networkingClient: networkingClient
        )

        let authClient = AuthClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            projectId: InputConfig.projectId,
            crypto: DefaultCryptoProvider(),
            logger: authLogger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient,
            pairingRegisterer: pairingClient,
            iatProvider: DefaultIATProvider())

        w3wClient = Web3WalletClientFactory.create(
            authClient: authClient,
            signClient: signClient,
            pairingClient: pairingClient,
            pushClient: PushClientMock())
    }

    func testSessionSettle() async throws {

        let expectation = expectation(description: "session settled")

        w3wClient.sessionProposalPublisher
            .sink { [unowned self] (proposal, _) in
                Task(priority: .high) {
                    let sessionNamespaces = SessionNamespace.make(toRespond: proposal.requiredNamespaces)
                    try await w3wClient.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                }
            }
            .store(in: &publishers)

        w3wClient.sessionSettlePublisher.sink { [unowned self] session in
            Task {
                var jsSession: JavaScriptAutoTestsAPI.Session?

                while jsSession == nil {
                    print("🎃 geting session")
                    do {
                        jsSession = try await javaScriptAutoTestsAPI.getSession(topic: session.topic)
                    } catch {
                        print("No session on JS client yet")
                    }

                    if jsSession == nil {
                        sleep(1)
                    }
                }

                XCTAssertEqual(jsSession?.topic, session.topic)
                expectation.fulfill()
            }
        }
        .store(in: &publishers)

        let pairingUri = try await javaScriptAutoTestsAPI.quickConnect()
        try await w3wClient.pair(uri: pairingUri)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

}


class JavaScriptAutoTestsAPI {
    private let host = "https://\(InputConfig.jsClientApiHost)"

    func quickConnect() async throws -> WalletConnectURI {
        let url = URL(string: "\(host)/quick_connect")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let uriString = String(decoding: data, as: UTF8.self)
        return WalletConnectURI(string: uriString)!
    }

    func getSession(topic: String) async throws -> Session {
        let url = URL(string: "\(host)/session/\(topic)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Session.self, from: data)
    }

    // Testing Data Structures to match JS responses

    struct Session: Decodable {
        let topic: String
    }
}
