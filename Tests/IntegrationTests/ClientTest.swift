
import Foundation
import XCTest
@testable import WalletConnect

final class ClientTests: XCTestCase {
    let url = URL(string: "wss://staging.walletconnect.org")!
    var proposer: ClientDelegate!
    var responder: ClientDelegate!
    override func setUp() {
        proposer = Self.makeClientDelegate(isController: false, url: url)
        responder = Self.makeClientDelegate(isController: true, url: url)
    }

    static func makeClientDelegate(isController: Bool, url: URL) -> ClientDelegate {
        let options = WalletClientOptions(apiKey: "", name: "", isController: isController, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil), relayURL: url)
        let client = WalletConnectClient(options: options)
        client.pairingEngine.sequencesStore = PairingDictionaryStore()
        client.sessionEngine.sequencesStore = SessionDictionaryStore()
        return ClientDelegate(client: client)
    }
    
    func testNewPairingWithoutSession() {
        let proposerSettlesPairingExpectation = expectation(description: "Proposer settles pairing")
        let responderSettlesPairingExpectation = expectation(description: "Responder settles pairing")
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onPairingSettled = { _ in
            responderSettlesPairingExpectation.fulfill()
        }
        proposer.onPairingSettled = { pairing in
            proposerSettlesPairingExpectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testNewSession() {
        let proposerSettlesSessionExpectation = expectation(description: "Proposer settles session")
        let responderSettlesSessionExpectation = expectation(description: "Responder settles session")
        let account = "0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"
        
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [account])
        }
        responder.onSessionSettled = { sessionSettled in
            XCTAssertEqual(account, sessionSettled.state.accounts[0])
            responderSettlesSessionExpectation.fulfill()
        }
        proposer.onSessionSettled = { sessionSettled in
            XCTAssertEqual(account, sessionSettled.state.accounts[0])
            proposerSettlesSessionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testProposerRequestExchangesSessionPayload() {
        let requestExpectation = expectation(description: "Responder receives request")
        let responseExpectation = expectation(description: "Proposer receives response")
        let method = "eth_signTypedData"
        let params = "params"
        let response = "response"
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: [method]))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = {[unowned self]  proposal in
            self.responder.client.approve(proposal: proposal, accounts: [])
        }
        proposer.onSessionSettled = {[unowned self]  settledSession in
            let requestParams = SessionType.PayloadRequestParams(topic: settledSession.topic, method: method, params: params, chainId: nil)
            self.proposer.client.request(params: requestParams) { result in
                switch result {
                case .success(let jsonRpcResponse):
                    XCTAssertEqual(jsonRpcResponse.result, response)
                    responseExpectation.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
        }
        responder.onSessionRequest = {[unowned self]  sessionRequest in
            XCTAssertEqual(sessionRequest.request.method, method)
            let jsonrpcResponse = JSONRPCResponse<AnyCodable>(id: sessionRequest.request.id, result: AnyCodable(response))
            self.responder.client.respond(topic: sessionRequest.topic, response: jsonrpcResponse)
            requestExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testResponderRejectsSession() {
        let sessionRejectExpectation = expectation(description: "Responded is notified on session rejection")
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = {[unowned self] proposal in
            self.responder.client.reject(proposal: proposal, reason: SessionType.Reason(code: WalletConnectError.notApproved.code, message: WalletConnectError.notApproved.description))
        }
        proposer.onSessionRejected = { _, reason in
            XCTAssertEqual(reason.code, WalletConnectError.notApproved.code)
            sessionRejectExpectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testDeleteSession() {
        let sessionDeleteExpectation = expectation(description: "Responder is notified on session deletion")
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = {[unowned self]  proposal in
            self.responder.client.approve(proposal: proposal, accounts: [])
        }
        proposer.onSessionSettled = {[unowned self]  settledSession in
            self.proposer.client.disconnect(topic: settledSession.topic, reason: SessionType.Reason(code: 5900, message: "User disconnected session"))
        }
        responder.onSessionDelete = {
            sessionDeleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
}

class ClientDelegate: WalletConnectClientDelegate {
    var client: WalletConnectClient
    var onSessionSettled: ((SessionType.Settled)->())?
    var onPairingSettled: ((PairingType.Settled)->())?
    var onSessionProposal: ((SessionType.Proposal)->())?
    var onSessionRequest: ((SessionRequest)->())?
    var onSessionRejected: ((String, SessionType.Reason)->())?
    var onSessionDelete: (()->())?

    internal init(client: WalletConnectClient) {
        self.client = client
        client.delegate = self
    }
    
    func didReject(sessionPendingTopic: String, reason: SessionType.Reason) {
        onSessionRejected?(sessionPendingTopic, reason)
    }
    func didSettle(session: SessionType.Settled) {
        onSessionSettled?(session)
    }
    func didSettle(pairing: PairingType.Settled) {
        onPairingSettled?(pairing)
    }
    func didReceive(sessionProposal: SessionType.Proposal) {
        onSessionProposal?(sessionProposal)
    }
    func didReceive(sessionRequest: SessionRequest) {
        onSessionRequest?(sessionRequest)
    }
    func didDelete(sessionTopic: String, reason: SessionType.Reason) {
        onSessionDelete?()
    }
}
