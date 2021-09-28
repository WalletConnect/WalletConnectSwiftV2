
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
        _ = try! responder.client.pair(uri: uri) { result in
            switch result {
            case .success(_):
                responderSettlesPairingExpectation.fulfill()
            case .failure(_):
                XCTFail()
            }
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
        _ = try! responder.client.pair(uri: uri) { _ in
        }
        responder.onSessionProposal = { proposal in
            responder.client.approve(proposal: proposal) { result in
                switch result {
                case .success(_):
                    break
                case .failure(_):
                    XCTFail()
                }
            }
        }
        responder.onSessionSettled = { _ in
            responderSettlesSessionExpectation.fulfill()
        }
        proposer.onSessionSettled = { _ in
            proposerSettlesSessionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testProposerSendRequest() {
        
    }
}

class ClientDelegate: WalletConnectClientDelegate {
    
    var client: WalletConnectClient
    var onSessionSettled: ((SessionType.Settled)->())?
    var onPairingSettled: ((PairingType.Settled)->())?
    var onSessionProposal: ((SessionType.Proposal)->())?
    var onSessionPayload: ((SessionType.PayloadParams, String)->())?

    internal init(client: WalletConnectClient) {
        self.client = client
        client.delegate = self
    }
    
    func didSettleSession(_ sessionSettled: SessionType.Settled) {
        onSessionSettled?(sessionSettled)
    }
    
    func didSettlePairing(_ settledPairing: PairingType.Settled) {
        onPairingSettled?(settledPairing)
    }
    func didReceive(sessionProposal: SessionType.Proposal) {
        onSessionProposal?(sessionProposal)
    }
    
    func didReceive(sessionPayload: SessionType.PayloadParams, on topic: String) {
        onSessionPayload?(sessionPayload, topic)
    }
}
