
import Foundation
import XCTest
@testable import WalletConnect

final class ClientTests: XCTestCase {
    
    let url = URL(string: "wss://relay.walletconnect.org")!

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
    
    func testProposerSendRequestToResponder() {
        let requestExpectation = expectation(description: "Responder receives request")
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
            let requestParams = SessionType.RequestParams(topic: settledSession.topic, method: method, params: params, chainId: nil)
            proposer.client.request(params: requestParams)
        }
        responder.onSessionRequest = { sessionRequest in
            XCTAssertEqual(sessionRequest.request.method, method)
            XCTAssertEqual(sessionRequest.request.params, params)
            responder.client.respond(topic: sessionRequest.topic, response: JSONRPCResponse<String>(response))
            requestExpectation.fulfill()
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

    internal init(client: WalletConnectClient) {
        self.client = client
        client.delegate = self
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
