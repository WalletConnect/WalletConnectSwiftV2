import XCTest
import WalletConnectUtils
@testable import WalletConnectKMS
@testable import WalletConnectSign
@testable import WalletConnectRelay

 struct EthSendTransaction: Codable, Equatable {
    let from: String
    let data: String
    let value: String
    let to: String
    let gasPrice: String
    let nonce: String
 }

 fileprivate let ethSendTransaction = """
   {
      "from":"0xb60e8dd61c5d32be8058bb8eb970870f07233155",
      "to":"0xd46e8dd67c5d32be8058bb8eb970870f07244567",
      "data":"0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
      "gas":"0x76c0",
      "gasPrice":"0x9184e72a000",
      "value":"0x9184e72a",
      "nonce":"0x117"
   }
 """

final class SignClientTests: XCTestCase {

    let defaultTimeout: TimeInterval = 5

    var proposer: ClientDelegate!
    var responder: ClientDelegate!

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
        proposer.onConnected = {
            group.leave()
        }
        group.enter()
        responder.onConnected = {
            group.leave()
        }
        group.wait()
        return
    }

    override func setUp() async throws {
        proposer = Self.makeClientDelegate(name: "🍏P")
        responder = Self.makeClientDelegate(name: "🍎R")
        await listenForConnection()
    }

    override func tearDown() {
        proposer = nil
        responder = nil
    }

    func testSessionPropose() async throws {
        let dapp = proposer!
        let wallet = responder!
        let dappSettlementExpectation = expectation(description: "Dapp expects to settle a session")
        let walletSettlementExpectation = expectation(description: "Wallet expects to settle a session")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { proposal in
            Task(priority: .high) {
                do { try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
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
        let dapp = proposer!
        let wallet = responder!
        let sessionRejectExpectation = expectation(description: "Proposer is notified on session rejection")

        class Store { var rejectedProposal: Session.Proposal? }
        let store = Store()

        let uri = try await dapp.client.connect(requiredNamespaces: ProposalNamespace.stubRequired())
        try await wallet.client.pair(uri: uri!)

        wallet.onSessionProposal = { proposal in
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
        let dapp = proposer!
        let wallet = responder!
        let sessionDeleteExpectation = expectation(description: "Wallet expects session to be deleted")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { proposal in
            Task(priority: .high) {
                do { try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
            }
        }
        dapp.onSessionSettled = { settledSession in
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
        let dapp = proposer!
        let wallet = responder!
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

    func testProposerRequestSessionRequest() async throws {
        let dapp = proposer!
        let wallet = responder!
        let requestExpectation = expectation(description: "Responder receives request")
        let responseExpectation = expectation(description: "Proposer receives response")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        let method = "eth_sendTransaction"
        let params = [try! JSONDecoder().decode(EthSendTransaction.self, from: ethSendTransaction.data(using: .utf8)!)]
        let responseParams = "0x4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c"

        wallet.onSessionProposal = { proposal in
            print("ON PROPOSAL")
            Task {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) }
                catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { settledSession in
            let requestParams = Request(id: 0, topic: settledSession.topic, method: method, params: AnyCodable(params), chainId: Blockchain("eip155:1")!)
            Task {
                try await dapp.client.request(params: requestParams)
            }
        }
        wallet.onSessionRequest = { sessionRequest in
            XCTAssertEqual(sessionRequest.method, method)
            let ethSendTrancastionParams = try! sessionRequest.params.get([EthSendTransaction].self)
            XCTAssertEqual(ethSendTrancastionParams, params)
            let jsonrpcResponse = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: AnyCodable(responseParams))
            Task {
                try await wallet.client.respond(topic: sessionRequest.topic, response: .response(jsonrpcResponse))
            }
            requestExpectation.fulfill()
        }
        dapp.onSessionResponse = { response in
            switch response.result {
            case .response(let jsonRpcResponse):
                let response = try! jsonRpcResponse.result.get(String.self)
                XCTAssertEqual(response, responseParams)
                responseExpectation.fulfill()
            case .error(_):
                XCTFail()
            }
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [requestExpectation, responseExpectation], timeout: defaultTimeout)
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
//    func testSessionRequestFailureResponse() async {
//        await waitClientsConnected()
//        let failureResponseExpectation = expectation(description: "Proposer receives failure response")
//        let method = "eth_sendTransaction"
//        let params = [try! JSONDecoder().decode(EthSendTransaction.self, from: ethSendTransaction.data(using: .utf8)!)]
//        let error = JSONRPCErrorResponse.Error(code: 0, message: "error_message")
//        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub(methods: [method])])!
//        _ = try! await responder.client.pair(uri: uri)
//        responder.onSessionProposal = {[unowned self]  proposal in
//            try? self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: proposal.namespaces)
//        }
//        proposer.onSessionSettled = {[unowned self]  settledSession in
//            let requestParams = Request(id: 0, topic: settledSession.topic, method: method, params: AnyCodable(params), chainId: Blockchain("eip155:1")!)
//            Task {
//                try await self.proposer.client.request(params: requestParams)
//            }
//        }
//        proposer.onSessionResponse = { response in
//            switch response.result {
//            case .response(_):
//                XCTFail()
//            case .error(let errorResponse):
//                XCTAssertEqual(error, errorResponse.error)
//                failureResponseExpectation.fulfill()
//            }
//
//        }
//        responder.onSessionRequest = {[unowned self]  sessionRequest in
//            let jsonrpcErrorResponse = JSONRPCErrorResponse(id: sessionRequest.id, error: error)
//            self.responder.client.respond(topic: sessionRequest.topic, response: .error(jsonrpcErrorResponse))
//        }
//        wait(for: [failureResponseExpectation], timeout: defaultTimeout)
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
