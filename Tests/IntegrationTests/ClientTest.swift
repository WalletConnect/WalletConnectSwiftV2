
import Foundation
import XCTest
import WalletConnectUtils
import TestingUtils
@testable import WalletConnect
@testable import WalletConnectKMS


final class ClientTests: XCTestCase {
    
    let defaultTimeout: TimeInterval = 5.0
    
    let relayHost = "relay.walletconnect.com"
    let projectId = "8ba9ee138960775e5231b70cc5ef1c3a"
    var proposer: ClientDelegate!
    var responder: ClientDelegate!
    
    override func setUp() {
        proposer = Self.makeClientDelegate(isController: false, relayHost: relayHost, prefix: "🍏P", projectId: projectId)
        responder = Self.makeClientDelegate(isController: true, relayHost: relayHost, prefix: "🍎R", projectId: projectId)
    }

    static func makeClientDelegate(isController: Bool, relayHost: String, prefix: String, projectId: String) -> ClientDelegate {
        let logger = ConsoleLogger(suffix: prefix, loggingLevel: .debug)
        let keychain = KeychainStorage(keychainService: KeychainServiceFake(), serviceIdentifier: "")
        let client = WalletConnectClient(
            metadata: AppMetadata(name: prefix, description: "", url: "", icons: [""]),
            projectId: projectId,
            relayHost: relayHost,
            logger: logger,
            kms: KeyManagementService(keychain: keychain),
            keyValueStorage: RuntimeKeyValueStorage())
        return ClientDelegate(client: client)
    }
    
    private func waitClientsConnected() async {
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
    
    func testNewPairingPing() async {
        let responderReceivesPingResponseExpectation = expectation(description: "Responder receives ping response")
        await waitClientsConnected()

        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
        
        try! responder.client.pair(uri: uri)
        let pairing = responder.client.getSettledPairings().first!
        responder.client.ping(topic: pairing.topic) { response in
            XCTAssertTrue(response.isSuccess)
            responderReceivesPingResponseExpectation.fulfill()
        }
        wait(for: [responderReceivesPingResponseExpectation], timeout: defaultTimeout)
    }

    func testNewSession() async {
        await waitClientsConnected()
        let proposerSettlesSessionExpectation = expectation(description: "Proposer settles session")
        let responderSettlesSessionExpectation = expectation(description: "Responder settles session")
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [account], namespaces: [])
        }
        responder.onSessionSettled = { sessionSettled in
            // FIXME: Commented assertion
//            XCTAssertEqual(account, sessionSettled.state.accounts[0])
            responderSettlesSessionExpectation.fulfill()
        }
        proposer.onSessionSettled = { sessionSettled in
            // FIXME: Commented assertion
//            XCTAssertEqual(account, sessionSettled.state.accounts[0])
            proposerSettlesSessionExpectation.fulfill()
        }
        wait(for: [proposerSettlesSessionExpectation, responderSettlesSessionExpectation], timeout: defaultTimeout)
    }
    
    func testNewSessionOnExistingPairing() async {
        await waitClientsConnected()
        let proposerSettlesSessionExpectation = expectation(description: "Proposer settles session")
        proposerSettlesSessionExpectation.expectedFulfillmentCount = 2
        let responderSettlesSessionExpectation = expectation(description: "Responder settles session")
        responderSettlesSessionExpectation.expectedFulfillmentCount = 2
        var initiatedSecondSession = false
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!

        try! responder.client.pair(uri: uri)

        responder.onSessionProposal = { [unowned self] proposal in
            responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
        }
        responder.onSessionSettled = { sessionSettled in
            responderSettlesSessionExpectation.fulfill()
        }
        proposer.onSessionSettled = { [unowned self] sessionSettled in
            proposerSettlesSessionExpectation.fulfill()
            let pairingTopic = proposer.client.getSettledPairings().first!.topic
            if !initiatedSecondSession {
                Task {
                    let _ = try! await proposer.client.connect(namespaces: [Namespace.stub()], topic: pairingTopic)
                }
                initiatedSecondSession = true
            }
        }
        wait(for: [proposerSettlesSessionExpectation, responderSettlesSessionExpectation], timeout: defaultTimeout)
    }

    func testResponderRejectsSession() async {
        await waitClientsConnected()
        let sessionRejectExpectation = expectation(description: "Proposer is notified on session rejection")
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
        _ = try! responder.client.pair(uri: uri)

        responder.onSessionProposal = {[unowned self] proposal in
            self.responder.client.reject(proposal: proposal, reason: .disapprovedChains)
        }
        proposer.onSessionRejected = { _, reason in
            XCTAssertEqual(reason.code, 5000)
            sessionRejectExpectation.fulfill()
        }
        wait(for: [sessionRejectExpectation], timeout: defaultTimeout)
    }
    
    func testDeleteSession() async {
        await waitClientsConnected()
        let sessionDeleteExpectation = expectation(description: "Responder is notified on session deletion")
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = {[unowned self]  proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
        }
        proposer.onSessionSettled = {[unowned self]  settledSession in
            Task {
                try await self.proposer.client.disconnect(topic: settledSession.topic, reason: Reason(code: 5900, message: "User disconnected session"))
            }
        }
        responder.onSessionDelete = {
            sessionDeleteExpectation.fulfill()
        }
        wait(for: [sessionDeleteExpectation], timeout: defaultTimeout)
    }
    
    func testProposerRequestSessionRequest() async {
        await waitClientsConnected()
        let requestExpectation = expectation(description: "Responder receives request")
        let responseExpectation = expectation(description: "Proposer receives response")
        let method = "eth_sendTransaction"
        let params = [try! JSONDecoder().decode(EthSendTransaction.self, from: ethSendTransaction.data(using: .utf8)!)]
        let responseParams = "0x4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c"
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub(methods: [method])])!

        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = {[unowned self]  proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: proposal.namespaces)
        }
        proposer.onSessionSettled = {[unowned self]  settledSession in
            let requestParams = Request(id: 0, topic: settledSession.topic, method: method, params: AnyCodable(params), chainId: Blockchain("eip155:1")!)
            Task {
                try await self.proposer.client.request(params: requestParams)
            }
        }
        proposer.onSessionResponse = { response in
            switch response.result {
            case .response(let jsonRpcResponse):
                let response = try! jsonRpcResponse.result.get(String.self)
                XCTAssertEqual(response, responseParams)
                responseExpectation.fulfill()
            case .error(_):
                XCTFail()
            }
        }
        responder.onSessionRequest = {[unowned self]  sessionRequest in
            XCTAssertEqual(sessionRequest.method, method)
            let ethSendTrancastionParams = try! sessionRequest.params.get([EthSendTransaction].self)
            XCTAssertEqual(ethSendTrancastionParams, params)
            let jsonrpcResponse = JSONRPCResponse<AnyCodable>(id: sessionRequest.id, result: AnyCodable(responseParams))
            self.responder.client.respond(topic: sessionRequest.topic, response: .response(jsonrpcResponse))
            requestExpectation.fulfill()
        }
        wait(for: [requestExpectation, responseExpectation], timeout: defaultTimeout)
    }
    
    
    func testSessionRequestFailureResponse() async {
        await waitClientsConnected()
        let failureResponseExpectation = expectation(description: "Proposer receives failure response")
        let method = "eth_sendTransaction"
        let params = [try! JSONDecoder().decode(EthSendTransaction.self, from: ethSendTransaction.data(using: .utf8)!)]
        let error = JSONRPCErrorResponse.Error(code: 0, message: "error_message")
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub(methods: [method])])!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = {[unowned self]  proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: proposal.namespaces)
        }
        proposer.onSessionSettled = {[unowned self]  settledSession in
            let requestParams = Request(id: 0, topic: settledSession.topic, method: method, params: AnyCodable(params), chainId: Blockchain("eip155:1")!)
            Task {
                try await self.proposer.client.request(params: requestParams)
            }
        }
        proposer.onSessionResponse = { response in
            switch response.result {
            case .response(_):
                XCTFail()
            case .error(let errorResponse):
                XCTAssertEqual(error, errorResponse.error)
                failureResponseExpectation.fulfill()
            }

        }
        responder.onSessionRequest = {[unowned self]  sessionRequest in
            let jsonrpcErrorResponse = JSONRPCErrorResponse(id: sessionRequest.id, error: error)
            self.responder.client.respond(topic: sessionRequest.topic, response: .error(jsonrpcErrorResponse))
        }
        wait(for: [failureResponseExpectation], timeout: defaultTimeout)
    }
    
    func testSessionPing() async {
        await waitClientsConnected()
        let proposerReceivesPingResponseExpectation = expectation(description: "Proposer receives ping response")
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!

        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
        }
        proposer.onSessionSettled = { [unowned self] sessionSettled in
            self.proposer.client.ping(topic: sessionSettled.topic) { response in
                XCTAssertTrue(response.isSuccess)
                proposerReceivesPingResponseExpectation.fulfill()
            }
        }
        wait(for: [proposerReceivesPingResponseExpectation], timeout: defaultTimeout)
    }
    
    func testSuccessfulSessionUpdateAccounts() async {
        await waitClientsConnected()
        let proposerSessionUpdateExpectation = expectation(description: "Proposer updates session on responder request")
        let responderSessionUpdateExpectation = expectation(description: "Responder updates session on proposer response")
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let updateAccounts: Set<Account> = [Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdf")!]
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [account], namespaces: [])
        }
        responder.onSessionSettled = { [unowned self] sessionSettled in
            try? responder.client.updateAccounts(topic: sessionSettled.topic, accounts: updateAccounts)
        }
        responder.onSessionUpdateAccounts = { _, accounts in
            XCTAssertEqual(accounts, updateAccounts)
            responderSessionUpdateExpectation.fulfill()
        }
        proposer.onSessionUpdateAccounts = { _, accounts in
            XCTAssertEqual(accounts, updateAccounts)
            proposerSessionUpdateExpectation.fulfill()
        }
        wait(for: [proposerSessionUpdateExpectation, responderSessionUpdateExpectation], timeout: defaultTimeout)
    }
    
    func testSuccessfulSessionUpdateNamespaces() async {
        await waitClientsConnected()
        let proposerSessionUpdateExpectation = expectation(description: "Proposer updates session methods on responder request")
        let responderSessionUpdateExpectation = expectation(description: "Responder updates session methods on proposer response")
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
        let namespacesToUpdateWith: Set<Namespace> = [Namespace(chains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], methods: ["xyz"], events: ["abc"])]
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
        }
        responder.onSessionSettled = { [unowned self] session in
            try? responder.client.updateNamespaces(topic: session.topic, namespaces: namespacesToUpdateWith)
        }
        proposer.onSessionUpdateNamespaces = { topic, namespaces in
            XCTAssertEqual(namespaces, namespacesToUpdateWith)
            proposerSessionUpdateExpectation.fulfill()
        }
        responder.onSessionUpdateNamespaces = { topic, namespaces in
            XCTAssertEqual(namespaces, namespacesToUpdateWith)
            responderSessionUpdateExpectation.fulfill()
        }
        wait(for: [proposerSessionUpdateExpectation, responderSessionUpdateExpectation], timeout: defaultTimeout)
    }
    
    func testSuccessfulSessionUpdateExpiry() async {
        await waitClientsConnected()
        let proposerSessionUpdateExpectation = expectation(description: "Proposer updates session expiry on responder request")
        let responderSessionUpdateExpectation = expectation(description: "Responder updates session expiry on proposer response")
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
        }
        responder.onSessionSettled = { [unowned self] session in
            Thread.sleep(forTimeInterval: 1) //sleep because new expiry must be greater than current
            try? responder.client.updateExpiry(topic: session.topic)
        }
        proposer.onSessionUpdateExpiry = { _, _ in
            proposerSessionUpdateExpectation.fulfill()
        }
        responder.onSessionUpdateExpiry = { _, _ in
            responderSessionUpdateExpectation.fulfill()
        }
        wait(for: [proposerSessionUpdateExpectation, responderSessionUpdateExpectation], timeout: defaultTimeout)
    }
    
    func testSessionEventSucceeds() async {
        await waitClientsConnected()
        let proposerReceivesEventExpectation = expectation(description: "Proposer receives event")
        let namespace = Namespace(chains: [], methods: [], events: ["type1"])
        let uri = try! await proposer.client.connect(namespaces: [namespace])!

        try! responder.client.pair(uri: uri)
        let event = Session.Event(name: "type1", data: AnyCodable("event_data"))
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [namespace])
        }
        responder.onSessionSettled = { [unowned self] session in
            responder.client.emit(topic: session.topic, event: event, chainId: nil, completion: nil)
        }
        proposer.onEventReceived = { event, _ in
            XCTAssertEqual(event, event)
            proposerReceivesEventExpectation.fulfill()
        }
        wait(for: [proposerReceivesEventExpectation], timeout: defaultTimeout)
    }
    
    func testSessionEventFails() async {
        await waitClientsConnected()
        let proposerReceivesEventExpectation = expectation(description: "Proposer receives event")
        proposerReceivesEventExpectation.isInverted = true
        let uri = try! await proposer.client.connect(namespaces: [Namespace.stub()])!

        try! responder.client.pair(uri: uri)
        let event = Session.Event(name: "type2", data: AnyCodable("event_data"))
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposalId: proposal.id, accounts: [], namespaces: [])
        }
        proposer.onSessionSettled = { [unowned self] session in
            proposer.client.emit(topic: session.topic, event: event, chainId: nil) { error in
                XCTAssertNotNil(error)
            }
        }
        responder.onEventReceived = { _, _ in
            XCTFail()
            proposerReceivesEventExpectation.fulfill()
        }
        wait(for: [proposerReceivesEventExpectation], timeout: defaultTimeout)
    }
}

public struct EthSendTransaction: Codable, Equatable {
    public let from: String
    public let data: String
    public let value: String
    public let to: String
    public let gasPrice: String
    public let nonce: String
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

extension Namespace {
    static func stub(methods: Set<String> = ["method"]) -> Namespace {
        Namespace(chains: [Blockchain("eip155:1")!], methods: methods, events: ["event"])
    }
}
