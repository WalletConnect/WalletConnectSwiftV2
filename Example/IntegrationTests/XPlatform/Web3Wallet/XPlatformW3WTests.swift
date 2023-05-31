import Foundation
import XCTest
import Web3Wallet
import Combine
import TestingUtils

final class XPlatformW3WTests: XCTestCase {
    var w3wClient: Web3WalletClient!
    var remoteClientController: RemoteClientController!
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

        let signClient = SignClientFactory.create(
            metadata: AppMetadata.stub(),
            pairingClient: pairingClient,
            networkingClient: networkingClient)

        let authClient = AuthClientFactory.create(
            metadata: AppMetadata.stub(),
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

        w3wClient.sessionProposalPublisher
            .sink { [unowned self] (proposal, _) in
                Task(priority: .high) {
                    let sessionNamespaces = SessionNamespace.make(toRespond: proposal.requiredNamespaces)
                    try await w3wClient.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                }
            }
            .store(in: &publishers)

        w3wClient.sessionRequestPublisher
            .sink { [unowned self] (request, _) in
                Task(priority: .high) {
                    try await w3wClient.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable("")))
                }
            }
            .store(in: &publishers)




        let pairingUri = try await remoteClientController.registerTest()
        try await w3wClient.pair(uri: pairingUri)

        wait(for: [], timeout: InputConfig.defaultTimeout)
    }
}


class RemoteClientController {
    private let httpClient: HTTPClient


    func registerTest() async throws -> WalletConnectURI {

    }


    func validateTest() async throws {
        
    }
    
    
}

