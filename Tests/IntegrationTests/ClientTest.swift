
import Foundation
import XCTest
@testable import WalletConnect

final class ClientTests: XCTestCase {
    
    let url = URL(string: "wss://staging.walletconnect.org")!

    func makeClientDelegate(isController: Bool) -> ClientDelegate {
        let options = WalletClientOptions(apiKey: "", name: "", isController: isController, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil), relayURL: url)
        let client = WalletConnectClient(options: options)
        return ClientDelegate(client: client)
    }
    
    func testNewPairingWithoutSession() {
        let proposerSettlesPairingExpectation = expectation(description: "Proposer settles pairing")
        let responderSettlesPairingExpectation = expectation(description: "Responder settles pairing")
        let proposer = makeClientDelegate(isController: false)
        let responder = makeClientDelegate(isController: true)
        
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
        let proposer = makeClientDelegate(isController: false)
        let responder = makeClientDelegate(isController: true)
        
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { proposal in
            responder.client.approve(proposal: proposal)
        }
        responder.onSessionSettled = { _ in
            responderSettlesSessionExpectation.fulfill()
        }
        proposer.onSessionSettled = { _ in
            proposerSettlesSessionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testProposerRequestExchangesSessionPayload() {
        let requestExpectation = expectation(description: "Responder receives request")
        let responseExpectation = expectation(description: "Proposer receives response")

        let proposer = makeClientDelegate(isController: false)
        let responder = makeClientDelegate(isController: true)
        let method = "eth_signTypedData"
        let params = "params"
        let response = "response"
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: [method]))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { proposal in
            responder.client.approve(proposal: proposal)
        }
        proposer.onSessionSettled = { settledSession in
            let requestParams = SessionType.PayloadRequestParams(topic: settledSession.topic, method: method, params: params, chainId: nil)
            proposer.client.request(params: requestParams) { result in
                switch result {
                case .success(let jsonRpcResponse):
                    XCTAssertEqual(jsonRpcResponse.result, response)
                    responseExpectation.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
        }
        responder.onSessionRequest = { sessionRequest in
            XCTAssertEqual(sessionRequest.request.method, method)
            XCTAssertEqual(sessionRequest.request.params, params)
            let jsonrpcResponse = JSONRPCResponse<String>(id: sessionRequest.request.id, result: response)
            responder.client.respond(topic: sessionRequest.topic, response: jsonrpcResponse)
            requestExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testResponderRejectsSession() {
        let sessionRejectExpectation = expectation(description: "Responded is notified on session rejection")
        let proposer = makeClientDelegate(isController: false)
        let responder = makeClientDelegate(isController: true)
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { proposal in
            responder.client.reject(proposal: proposal, reason: SessionType.Reason(code: WalletConnectError.sessionNotApproved.code, message: WalletConnectError.sessionNotApproved.description))
        }
        proposer.onSessionRejected = { _, reason in
            XCTAssertEqual(reason.code, WalletConnectError.sessionNotApproved.code)
            sessionRejectExpectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}

class ClientDelegate: WalletConnectClientDelegate {
    var client: WalletConnectClient
    var onSessionSettled: ((SessionType.Settled)->())?
    var onPairingSettled: ((PairingType.Settled)->())?
    var onSessionProposal: ((SessionType.Proposal)->())?
    var onSessionRequest: ((SessionRequest)->())?
    var onSessionRejected: ((String, SessionType.Reason)->())?

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
}
