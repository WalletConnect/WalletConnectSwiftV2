import Foundation
import XCTest
@testable import WalletConnectUtils
@testable import WalletConnectKMS
import WalletConnectRelay
import Combine
import WalletConnectNetworking
import WalletConnectPush
@testable import Auth
@testable import WalletConnectPairing
@testable import WalletConnectSync
@testable import WalletConnectHistory

final class PairingTests: XCTestCase {

    var appPairingClient: PairingClient!
    var walletPairingClient: PairingClient!

    var appAuthClient: AuthClient!
    var walletAuthClient: AuthClient!

    var pairingStorage: PairingStorage!

    private var publishers = [AnyCancellable]()

    func makeClients(prefix: String, includeAuth: Bool = true) -> (PairingClient, AuthClient?) {
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()

        let logger = ConsoleLogger(prefix: prefix, loggingLevel: .debug)

        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            logger: logger)

        let networkingClient = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: logger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage)

        let pairingClient = PairingClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient)


        let clientId = try! networkingClient.getClientId()
        logger.debug("My client id is: \(clientId)")

        if includeAuth {
            let authClient = AuthClientFactory.create(
                metadata: AppMetadata(name: name, description: "", url: "", icons: [""], redirect: AppMetadata.Redirect(native: "", universal: nil)),
                projectId: InputConfig.projectId,
                crypto: DefaultCryptoProvider(),
                logger: logger,
                keyValueStorage: keyValueStorage,
                keychainStorage: keychain,
                networkingClient: networkingClient,
                pairingRegisterer: pairingClient,
                iatProvider: IATProviderMock())

            return (pairingClient, authClient)
        } else {
            return (pairingClient, nil)
        }
    }

    override func setUp() {
        (appPairingClient, appAuthClient) = makeClients(prefix: "🤖 Dapp: ")
        (walletPairingClient, _) = makeClients(prefix: "🐶 Wallet: ", includeAuth: false)
    }

    func testPing() async {
        let expectation = expectation(description: "expects ping response")
        let uri = try! await appPairingClient.create()
        try? await walletPairingClient.pair(uri: uri)
        try! await walletPairingClient.ping(topic: uri.topic)
        walletPairingClient.pingResponsePublisher
            .sink { topic in
                XCTAssertEqual(topic, uri.topic)
                expectation.fulfill()
            }.store(in: &publishers)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testResponseErrorForMethodUnregistered() async {
        let expectation = expectation(description: "wallet responds unsupported method for unregistered method")

        appAuthClient.authResponsePublisher.sink { (_, response) in
            XCTAssertEqual(response, .failure(AuthError(code: 10001)!))
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try! await walletPairingClient.pair(uri: uri)

        try! await appAuthClient.request(RequestParams.stub(), topic: uri.topic)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testDisconnect() async {

        let expectation = expectation(description: "wallet disconnected pairing")


        walletPairingClient.pairingDeletePublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await appPairingClient.create()

        try? await walletPairingClient.pair(uri: uri)

        try! await appPairingClient.disconnect(topic: uri.topic)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }
}
