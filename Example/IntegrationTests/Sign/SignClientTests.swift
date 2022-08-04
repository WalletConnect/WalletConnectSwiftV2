import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import WalletConnectSign
@testable import WalletConnectRelay

final class SignClientTests: XCTestCase {

    let defaultTimeout: TimeInterval = 5

    var dapp: ClientDelegate!
    var wallet: ClientDelegate!

    static private func makeClientDelegate(
        name: String,
        relayHost: String = "relay.walletconnect.com",
        projectId: String = "8ba9ee138960775e5231b70cc5ef1c3a"
    ) -> ClientDelegate {
        let logger = ConsoleLogger(suffix: name, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(
            relayHost: relayHost,
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
                    try await wallet.client.reject(proposalId: proposal.id, reason: .disapprovedChains) // TODO: Review reason
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

        let pairing = wallet.client.getSettledPairings().first!
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
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) }
                catch {
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

//
//    func testNewSessionOnExistingPairing() async {
//        await waitClientsConnected()
//        let proposerSettlesSessionExpectation = expectation(description: "Proposer settles session")
//        proposerSettlesSessionExpectation.expectedFulfillmentCount = 2
//        let responderSettlesSessionExpectation = expectation(description: "Responder settles session")
//        responderSettlesSessionExpectation.expectedFulfillmentCount = 2
//        var initiatedSecondSession = false
//        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
//
//        try! await responder.client.pair(uri: uri)
//
//        responder.onSessionProposal = { [unowned self] proposal in
//            try? responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
//        }
//        responder.onSessionSettled = { sessionSettled in
//            responderSettlesSessionExpectation.fulfill()
//        }
//        proposer.onSessionSettled = { [unowned self] sessionSettled in
//            proposerSettlesSessionExpectation.fulfill()
//            let pairingTopic = proposer.client.getSettledPairings().first!.topic
//            if !initiatedSecondSession {
//                Task {
//                    let _ = try! await proposer.client.connect(namespaces: [Namespace.stub()], topic: pairingTopic)
//                }
//                initiatedSecondSession = true
//            }
//        }
//        wait(for: [proposerSettlesSessionExpectation, responderSettlesSessionExpectation], timeout: defaultTimeout)
//    }
//
//    func testSessionPing() async {
//        await waitClientsConnected()
//        let proposerReceivesPingResponseExpectation = expectation(description: "Proposer receives ping response")
//        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
//
//        try! await responder.client.pair(uri: uri)
//        responder.onSessionProposal = { [unowned self] proposal in
//            try? self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
//        }
//        proposer.onSessionSettled = { [unowned self] sessionSettled in
//            self.proposer.client.ping(topic: sessionSettled.topic) { response in
//                XCTAssertTrue(response.isSuccess)
//                proposerReceivesPingResponseExpectation.fulfill()
//            }
//        }
//        wait(for: [proposerReceivesPingResponseExpectation], timeout: defaultTimeout)
//    }
//
//    func testSuccessfulSessionUpdateNamespaces() async {
//        await waitClientsConnected()
//        let proposerSessionUpdateExpectation = expectation(description: "Proposer updates session methods on responder request")
//        let responderSessionUpdateExpectation = expectation(description: "Responder updates session methods on proposer response")
//        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
//        let namespacesToUpdateWith: Set<Namespace> = [Namespace(chains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], methods: ["xyz"], events: ["abc"])]
//        try! await responder.client.pair(uri: uri)
//        responder.onSessionProposal = { [unowned self] proposal in
//            try? self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
//        }
//        responder.onSessionSettled = { [unowned self] session in
//            try? responder.client.updateNamespaces(topic: session.topic, namespaces: namespacesToUpdateWith)
//        }
//        proposer.onSessionUpdateNamespaces = { topic, namespaces in
//            XCTAssertEqual(namespaces, namespacesToUpdateWith)
//            proposerSessionUpdateExpectation.fulfill()
//        }
//        responder.onSessionUpdateNamespaces = { topic, namespaces in
//            XCTAssertEqual(namespaces, namespacesToUpdateWith)
//            responderSessionUpdateExpectation.fulfill()
//        }
//        wait(for: [proposerSessionUpdateExpectation, responderSessionUpdateExpectation], timeout: defaultTimeout)
//    }
//
//    func testSuccessfulSessionUpdateExpiry() async {
//        await waitClientsConnected()
//        let proposerSessionUpdateExpectation = expectation(description: "Proposer updates session expiry on responder request")
//        let responderSessionUpdateExpectation = expectation(description: "Responder updates session expiry on proposer response")
//        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
//        try! await responder.client.pair(uri: uri)
//        responder.onSessionProposal = { [unowned self] proposal in
//            try? self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
//        }
//        responder.onSessionSettled = { [unowned self] session in
//            Thread.sleep(forTimeInterval: 1) //sleep because new expiry must be greater than current
//            try? responder.client.updateExpiry(topic: session.topic)
//        }
//        proposer.onSessionUpdateExpiry = { _, _ in
//            proposerSessionUpdateExpectation.fulfill()
//        }
//        responder.onSessionUpdateExpiry = { _, _ in
//            responderSessionUpdateExpectation.fulfill()
//        }
//        wait(for: [proposerSessionUpdateExpectation, responderSessionUpdateExpectation], timeout: defaultTimeout)
//    }
//
//    func testSessionEventSucceeds() async {
//        await waitClientsConnected()
//        let proposerReceivesEventExpectation = expectation(description: "Proposer receives event")
//        let namespace = Namespace(chains: [Blockchain("eip155:1")!], methods: [], events: ["type1"]) // TODO: Fix namespace with empty chain array / protocol change
//        let uri = try! await proposer.client.connect(namespaces: [namespace])!
//
//        try! await responder.client.pair(uri: uri)
//        let event = Session.Event(name: "type1", data: AnyCodable("event_data"))
//        responder.onSessionProposal = { [unowned self] proposal in
//            try? self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [namespace])
//        }
//        responder.onSessionSettled = { [unowned self] session in
//            Task{try? await responder.client.emit(topic: session.topic, event: event, chainId: Blockchain("eip155:1")!)}
//        }
//        proposer.onEventReceived = { event, _ in
//            XCTAssertEqual(event, event)
//            proposerReceivesEventExpectation.fulfill()
//        }
//        wait(for: [proposerReceivesEventExpectation], timeout: defaultTimeout)
//    }
//
//    func testSessionEventFails() async {
//        await waitClientsConnected()
//        let proposerReceivesEventExpectation = expectation(description: "Proposer receives event")
//        proposerReceivesEventExpectation.isInverted = true
//        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
//
//        try! await responder.client.pair(uri: uri)
//        let event = Session.Event(name: "type2", data: AnyCodable("event_data"))
//        responder.onSessionProposal = { [unowned self] proposal in
//            try? self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
//        }
//        proposer.onSessionSettled = { [unowned self] session in
//            Task {await XCTAssertThrowsErrorAsync(try await proposer.client.emit(topic: session.topic, event: event, chainId: Blockchain("eip155:1")!))}
//        }
//        responder.onEventReceived = { _, _ in
//            XCTFail()
//            proposerReceivesEventExpectation.fulfill()
//        }
//        wait(for: [proposerReceivesEventExpectation], timeout: defaultTimeout)
//    }
}
