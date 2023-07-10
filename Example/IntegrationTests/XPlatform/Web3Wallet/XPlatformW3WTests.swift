import Foundation
import XCTest
import Combine
@testable import Web3Wallet
@testable import Auth
@testable import WalletConnectEcho

final class XPlatformW3WTests: XCTestCase {
    var w3wClient: Web3WalletClient!
    var javaScriptAutoTestsAPI: JavaScriptAutoTestsAPI!
    private var publishers = [AnyCancellable]()

    override func setUp() {
        makeClient()
    }

    func makeClient() {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let relayLogger = ConsoleLogger(suffix: "🚄" + " [Relay]", loggingLevel: .debug)
        let pairingLogger = ConsoleLogger(suffix: "👩‍❤️‍💋‍👩" + " [Pairing]", loggingLevel: .debug)
        let networkingLogger = ConsoleLogger(suffix: "🕸️" + " [Networking]", loggingLevel: .debug)
        let authLogger = ConsoleLogger(suffix: "✍🏿", loggingLevel: .debug)

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
            metadata: AppMetadata.stub(),
            pairingClient: pairingClient,
            networkingClient: networkingClient)

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
            echoClient: EchoClientMock())
    }

    func testSessionRequest() async throws {

        let expectation = expectation(description: "session settled")
        w3wClient.sessionProposalPublisher
            .sink { [unowned self] (proposal, _) in
                Task(priority: .high) {
                    let sessionNamespaces = SessionNamespace.make(toRespond: proposal.requiredNamespaces)
                    try await w3wClient.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                }
            }
            .store(in: &publishers)

        w3wClient.sessionSettlePublisher.sink { _ in
            expectation.fulfill()
        }
        .store(in: &publishers)

        let pairingUri = try await javaScriptAutoTestsAPI.quickConnect()
        try await w3wClient.pair(uri: pairingUri)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }
}


class JavaScriptAutoTestsAPI {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func quickConnect() async throws -> WalletConnectURI {
        let endpoint = Endpoint(path: "/quick_connect", method: .get)
        return try await httpClient.request(WalletConnectURI.self, at: endpoint)
    }
}


struct Endpoint: HTTPService {
    var path: String

    var method: HTTPMethod

    var body: Data?

    var queryParameters: [String : String]?

    var additionalHeaderFields: [String : String]?

    init(path: String, method: HTTPMethod, body: Data? = nil, queryParameters: [String : String]? = nil, additionalHeaderFields: [String : String]? = nil) {
        self.path = path
        self.method = method
        self.body = body
        self.queryParameters = queryParameters
        self.additionalHeaderFields = additionalHeaderFields
    }


}
