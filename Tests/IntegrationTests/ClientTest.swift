
import Foundation
import XCTest
@testable import WalletConnect

final class ClientTests: XCTestCase {
    let url = URL(string: "wss://staging.walletconnect.org")! // TODO: Change to new URL
    var proposer: ClientDelegate!
    var responder: ClientDelegate!
    override func setUp() {
        proposer = Self.makeClientDelegate(isController: false, url: url, prefix: "🍏P")
        responder = Self.makeClientDelegate(isController: true, url: url, prefix: "🍎R")
    }

    static func makeClientDelegate(isController: Bool, url: URL, prefix: String) -> ClientDelegate {
        let logger = ConsoleLogger(suffix: prefix)
        let client = WalletConnectClient(
            metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil),
            apiKey: "",
            isController: isController,
            relayURL: url,
            logger: logger,
            keyValueStore: RuntimeKeyValueStorage(),
            keychain: KeychainStorage(keychainService: KeychainServiceFake()))
        client.sessionEngine.sequencesStore = SessionDictionaryStore(logger: logger)
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
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testNewSession() {
        let proposerSettlesSessionExpectation = expectation(description: "Proposer settles session")
        let responderSettlesSessionExpectation = expectation(description: "Responder settles session")
        let account = "0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"
        
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [account])
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
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testNewSessionOnExistingPairing() {
        let proposerSettlesSessionExpectation = expectation(description: "Proposer settles session")
        proposerSettlesSessionExpectation.expectedFulfillmentCount = 2
        let responderSettlesSessionExpectation = expectation(description: "Responder settles session")
        responderSettlesSessionExpectation.expectedFulfillmentCount = 2
        var pairingTopic: String!
        var initiatedSecondSession = false
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        proposer.onPairingSettled = { pairing in
            pairingTopic = pairing.topic
        }
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [])
        }
        responder.onSessionSettled = { sessionSettled in
            responderSettlesSessionExpectation.fulfill()
        }
        proposer.onSessionSettled = { [unowned self] sessionSettled in
            proposerSettlesSessionExpectation.fulfill()
            if !initiatedSecondSession {
                let params = ConnectParams(permissions: SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: [])), topic: pairingTopic)
                let _ = try! proposer.client.connect(params: params)
                initiatedSecondSession = true
            }
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
            self.responder.client.reject(proposal: proposal, reason: SessionType.Reason(code: WalletConnectError.internal(.notApproved).code, message: WalletConnectError.internal(.notApproved).description))
        }
        proposer.onSessionRejected = { _, reason in
            XCTAssertEqual(reason.code, WalletConnectError.internal(.notApproved).code)
            sessionRejectExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
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
    
    func testProposerRequestSessionPayload() {
        let requestExpectation = expectation(description: "Responder receives request")
        let responseExpectation = expectation(description: "Proposer receives response")
        let method = "eth_sendTransaction"
        let params = [try! JSONDecoder().decode(EthSendTransaction.self, from: ethSendTransaction.data(using: .utf8)!)]
        let responseParams = "0x4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c"
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: [method]))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        responder.onSessionProposal = {[unowned self]  proposal in
            self.responder.client.approve(proposal: proposal, accounts: [])
        }
        proposer.onSessionSettled = {[unowned self]  settledSession in
            let requestParams = SessionType.PayloadRequestParams(topic: settledSession.topic, method: method, params: AnyCodable(params), chainId: nil)
            self.proposer.client.request(params: requestParams) { result in
                switch result {
                case .success(let jsonRpcResponse):
                    let response = try! jsonRpcResponse.result.get(String.self)
                    XCTAssertEqual(response, responseParams)
                    responseExpectation.fulfill()
                case .failure(_):
                    XCTFail()
                }
            }
        }
        responder.onSessionRequest = {[unowned self]  sessionRequest in
            XCTAssertEqual(sessionRequest.request.method, method)
            let ethSendTrancastionParams = try! sessionRequest.request.params.get([EthSendTransaction].self)
            XCTAssertEqual(ethSendTrancastionParams, params)
            let jsonrpcResponse = JSONRPCResponse<AnyCodable>(id: sessionRequest.request.id, result: AnyCodable(responseParams))
            self.responder.client.respond(topic: sessionRequest.topic, response: jsonrpcResponse)
            requestExpectation.fulfill()
        }
        waitForExpectations(timeout: 4.0, handler: nil)
    }
    
    func testPairingPing() {
        let proposerReceivesPingResponseExpectation = expectation(description: "Proposer receives ping response")
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        
        _ = try! responder.client.pair(uri: uri)
        proposer.onPairingSettled = { [unowned self] pairing in
            proposer.client.ping(topic: pairing.topic) { response in
                XCTAssertTrue(response.isSuccess)
                proposerReceivesPingResponseExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    
    func testSessionPing() {
        let proposerReceivesPingResponseExpectation = expectation(description: "Proposer receives ping response")
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [])
        }
        proposer.onSessionSettled = { [unowned self] sessionSettled in
            self.proposer.client.ping(topic: sessionSettled.topic) { response in
                XCTAssertTrue(response.isSuccess)
                proposerReceivesPingResponseExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 4.0, handler: nil)
    }
    
    func testSuccessfulSessionUpgrade() {
        let proposerSessionUpgradeExpectation = expectation(description: "Proposer upgrades session on responder request")
        let responderSessionUpgradeExpectation = expectation(description: "Responder upgrades session on proposer response")
        let account = "0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let upgradePermissions = SessionPermissions(blockchains: ["eip155:42"], methods: ["eth_sendTransaction"])
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [account])
        }
        responder.onSessionSettled = { [unowned self] sessionSettled in
            responder.client.upgrade(topic: sessionSettled.topic, permissions: upgradePermissions)
        }
        proposer.onSessionUpgrade = { topic, permissions in
            XCTAssertTrue(permissions.blockchain.chains.isSuperset(of: upgradePermissions.blockchains))
            XCTAssertTrue(permissions.jsonrpc.methods.isSuperset(of: upgradePermissions.methods))
            proposerSessionUpgradeExpectation.fulfill()
        }
        responder.onSessionUpgrade = { topic, permissions in
            XCTAssertTrue(permissions.blockchain.chains.isSuperset(of: upgradePermissions.blockchains))
            XCTAssertTrue(permissions.jsonrpc.methods.isSuperset(of: upgradePermissions.methods))
            responderSessionUpgradeExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testSessionUpgradeFailsOnNonControllerRequest() {
        let proposerSessionUpgradeExpectation = expectation(description: "Proposer upgrades session")
        proposerSessionUpgradeExpectation.isInverted = true
        let responderSessionUpgradeExpectation = expectation(description: "Responder upgrades session")
        responderSessionUpgradeExpectation.isInverted = true
        let account = "0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let upgradePermissions = SessionPermissions(blockchains: ["eip155:42"], methods: ["eth_sendTransaction"])
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [account])
        }
        proposer.onSessionSettled = { [unowned self] sessionSettled in
            proposer.client.upgrade(topic: sessionSettled.topic, permissions: upgradePermissions)
        }
        proposer.onSessionUpgrade = { topic, permissions in
            proposerSessionUpgradeExpectation.fulfill()
        }
        responder.onSessionUpgrade = { topic, permissions in
            responderSessionUpgradeExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testSuccessfulSessionUpdate() {
        let proposerSessionUpdateExpectation = expectation(description: "Proposer updates session on responder request")
        let responderSessionUpdateExpectation = expectation(description: "Responder updates session on proposer response")
        let account = "eip155:42:0x022c0c42a80bd19EA4cF0F94c4F9F96645759716"
        let updateAccounts: Set<String> = ["eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb"]
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [account])
        }
        responder.onSessionSettled = { [unowned self] sessionSettled in
            responder.client.update(topic: sessionSettled.topic, accounts: updateAccounts)
        }
        responder.onSessionUpdate = { _, accounts in
            XCTAssertEqual(accounts, updateAccounts)
            responderSessionUpdateExpectation.fulfill()
        }
        proposer.onSessionUpdate = { _, accounts in
            XCTAssertEqual(accounts, updateAccounts)
            proposerSessionUpdateExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testSessionNotificationSucceeds() {
        let proposerReceivesNotificationExpectation = expectation(description: "Proposer receives notification")
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []), notifications: SessionType.Notifications(types: ["type1"]))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        let notificationParams = SessionType.NotificationParams(type: "type1", data: AnyCodable("notification_data"))
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [])
        }
        responder.onSessionSettled = { [unowned self] session in
            responder.client.notify(topic: session.topic, params: notificationParams, completion: nil)
        }
        proposer.onNotificationReceived = { notification, _ in
            XCTAssertEqual(notification, notificationParams)
            proposerReceivesNotificationExpectation.fulfill()
        }
        waitForExpectations(timeout: 13.0, handler: nil)
    }
    
    func testSessionNotificationFails() {
        let proposerReceivesNotificationExpectation = expectation(description: "Proposer receives notification")
        proposerReceivesNotificationExpectation.isInverted = true
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []), notifications: SessionType.Notifications(types: ["type1"]))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        try! responder.client.pair(uri: uri)
        let notificationParams = SessionType.NotificationParams(type: "type2", data: AnyCodable("notification_data"))
        responder.onSessionProposal = { [unowned self] proposal in
            self.responder.client.approve(proposal: proposal, accounts: [])
        }
        proposer.onSessionSettled = { [unowned self] session in
            proposer.client.notify(topic: session.topic, params: notificationParams) { error in
                XCTAssertNotNil(error)
            }
        }
        responder.onNotificationReceived = { notification, _ in
            XCTFail()
            proposerReceivesNotificationExpectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testPairingUpdate() {
        let proposerReceivesPairingUpdateExpectation = expectation(description: "Proposer receives pairing update")
        let permissions = SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []))
        let connectParams = ConnectParams(permissions: permissions)
        let uri = try! proposer.client.connect(params: connectParams)!
        _ = try! responder.client.pair(uri: uri)
        proposer.onPairingUpdate = { _, appMetadata in
            XCTAssertNotNil(appMetadata)
            proposerReceivesPairingUpdateExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
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
