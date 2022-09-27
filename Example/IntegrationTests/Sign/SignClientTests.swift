import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import WalletConnectSign
@testable import WalletConnectRelay

final class SignClientTests: XCTestCase {

    private let defaultTimeout: TimeInterval = 30

    var dapp: ClientDelegate!
    var wallet: ClientDelegate!

    static private func makeClientDelegate(
        name: String,
        projectId: String = "3ca2919724fbfa5456a25194e369a8b4"
    ) -> ClientDelegate {
        let logger = ConsoleLogger(suffix: name, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(
            relayHost: URLConfig.relayHost,
            projectId: projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: SocketFactory(),
            socketConnectionType: .automatic,
            logger: logger
        )
        let client = SignClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            logger: logger,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            relayClient: relayClient
        )
        return ClientDelegate(client: client)
    }

    private func listenForConnection() async {
        let group = DispatchGroup()
        group.enter()
        dapp.onConnected = {
            group.leave()
        }
        group.enter()
        wallet.onConnected = {
            group.leave()
        }
        group.wait()
        return
    }

    override func setUp() async throws {
        dapp = Self.makeClientDelegate(name: "🍏P")
        wallet = Self.makeClientDelegate(name: "🍎R")
        await listenForConnection()
    }

    override func tearDown() {
        dapp = nil
        wallet = nil
    }

    func testSessionPropose() async throws {
        let dappSettlementExpectation = expectation(description: "Dapp expects to settle a session")
        let walletSettlementExpectation = expectation(description: "Wallet expects to settle a session")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { _ in
            dappSettlementExpectation.fulfill()
        }
        wallet.onSessionSettled = { _ in
            walletSettlementExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [dappSettlementExpectation, walletSettlementExpectation], timeout: defaultTimeout)
    }

    func testSessionReject() async throws {
        let sessionRejectExpectation = expectation(description: "Proposer is notified on session rejection")

        class Store { var rejectedProposal: Session.Proposal? }
        let store = Store()

        let uri = try await dapp.client.connect(requiredNamespaces: ProposalNamespace.stubRequired())
        try await wallet.client.pair(uri: uri!)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.reject(proposalId: proposal.id, reason: .userRejectedChains) // TODO: Review reason
                    store.rejectedProposal = proposal
                } catch { XCTFail("\(error)") }
            }
        }
        dapp.onSessionRejected = { proposal, _ in
            XCTAssertEqual(store.rejectedProposal, proposal)
            sessionRejectExpectation.fulfill() // TODO: Assert reason code
        }
        wait(for: [sessionRejectExpectation], timeout: defaultTimeout)
    }

    func testSessionDelete() async throws {
        let sessionDeleteExpectation = expectation(description: "Wallet expects session to be deleted")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do { try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try await dapp.client.disconnect(topic: settledSession.topic)
            }
        }
        wallet.onSessionDelete = {
            sessionDeleteExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [sessionDeleteExpectation], timeout: defaultTimeout)
    }

    func testNewPairingPing() async throws {
        let pongResponseExpectation = expectation(description: "Ping sender receives a pong response")

        let uri = try await dapp.client.connect(requiredNamespaces: ProposalNamespace.stubRequired())!
        try await wallet.client.pair(uri: uri)

        let pairing = wallet.client.getPairings().first!
        wallet.client.ping(topic: pairing.topic) { result in
            if case .failure = result { XCTFail() }
            pongResponseExpectation.fulfill()
        }
        wait(for: [pongResponseExpectation], timeout: defaultTimeout)
    }

    func testSessionRequest() async throws {
        let requestExpectation = expectation(description: "Wallet expects to receive a request")
        let responseExpectation = expectation(description: "Dapp expects to receive a response")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        let requestMethod = "eth_sendTransaction"
        let requestParams = [EthSendTransaction.stub()]
        let responseParams = "0xdeadbeef"
        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                let request = Request(id: 0, topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain)
                try await dapp.client.request(params: request)
            }
        }
        wallet.onSessionRequest = { [unowned self] sessionRequest in
            let receivedParams = try! sessionRequest.params.get([EthSendTransaction].self)
            XCTAssertEqual(receivedParams, requestParams)
            XCTAssertEqual(sessionRequest.method, requestMethod)
            requestExpectation.fulfill()
            Task(priority: .high) {
                let jsonrpcResponse = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: AnyCodable(responseParams))
                try await wallet.client.respond(topic: sessionRequest.topic, response: .response(jsonrpcResponse))
            }
        }
        dapp.onSessionResponse = { response in
            switch response.result {
            case .response(let response):
                XCTAssertEqual(try! response.result.get(String.self), responseParams)
            case .error:
                XCTFail()
            }
            responseExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [requestExpectation, responseExpectation], timeout: defaultTimeout)
    }

    func testSessionRequestFailureResponse() async throws {
        let expectation = expectation(description: "Dapp expects to receive an error response")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        let requestMethod = "eth_sendTransaction"
        let requestParams = [EthSendTransaction.stub()]
        let error = JSONRPCErrorResponse.Error(code: 0, message: "error")
        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                let request = Request(id: 0, topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain)
                try await dapp.client.request(params: request)
            }
        }
        wallet.onSessionRequest = { [unowned self] sessionRequest in
            Task(priority: .high) {
                let response = JSONRPCErrorResponse(id: sessionRequest.id, error: error)
                try await wallet.client.respond(topic: sessionRequest.topic, response: .error(response))
            }
        }
        dapp.onSessionResponse = { response in
            switch response.result {
            case .response:
                XCTFail()
            case .error(let errorResponse):
                XCTAssertEqual(error, errorResponse.error)
            }
            expectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [expectation], timeout: defaultTimeout)
    }


    func testNewSessionOnExistingPairing() async {
        let dappSettlementExpectation = expectation(description: "Dapp settles session")
        dappSettlementExpectation.expectedFulfillmentCount = 2
        let walletSettlementExpectation = expectation(description: "Wallet settles session")
        walletSettlementExpectation.expectedFulfillmentCount = 2
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        var initiatedSecondSession = false

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { [unowned self] _ in
            dappSettlementExpectation.fulfill()
            let pairingTopic = dapp.client.getPairings().first!.topic
            if !initiatedSecondSession {
                Task(priority: .high) {
                    let _ = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces, topic: pairingTopic)
                }
                initiatedSecondSession = true
            }
        }
        wallet.onSessionSettled = { _ in
            walletSettlementExpectation.fulfill()
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)
        wait(for: [dappSettlementExpectation, walletSettlementExpectation], timeout: defaultTimeout)

    }

    func testSessionPing() async {
        let expectation = expectation(description: "Dapp receives ping response")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            dapp.client.ping(topic: settledSession.topic) {_ in
                expectation.fulfill()
            }
        }
        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)
        wait(for: [expectation], timeout: defaultTimeout)
    }


    func testSuccessfulSessionUpdateNamespaces() async {
        let expectation = expectation(description: "Dapp updates namespaces")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.client.update(topic: settledSession.topic, namespaces: sessionNamespaces)
            }
        }
        dapp.onSessionUpdateNamespaces = { _, _ in
            expectation.fulfill()
        }
        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)
        wait(for: [expectation], timeout: defaultTimeout)
    }


    func testSuccessfulSessionExtend() async {
        let expectation = expectation(description: "Dapp extends session")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }

        dapp.onSessionExtend = { _, _ in
            expectation.fulfill()
        }

        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.client.extend(topic: settledSession.topic)
            }
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)

        wait(for: [expectation], timeout: defaultTimeout)
    }

    func testSessionEventSucceeds() async {
        let expectation = expectation(description: "Dapp receives session event")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        let event = Session.Event(name: "any", data: AnyCodable("event_data"))
        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }

        dapp.onEventReceived = { _, _ in
            expectation.fulfill()
        }

        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.client.emit(topic: settledSession.topic, event: event, chainId: chain)
            }
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)

        wait(for: [expectation], timeout: defaultTimeout)
    }

    func testSessionEventFails() async {
        let expectation = expectation(description: "Dapp receives session event")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        let event = Session.Event(name: "unknown", data: AnyCodable("event_data"))
        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }

        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                await XCTAssertThrowsErrorAsync(try await wallet.client.emit(topic: settledSession.topic, event: event, chainId: chain))
                expectation.fulfill()
            }
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)

        wait(for: [expectation], timeout: defaultTimeout)
    }
}
