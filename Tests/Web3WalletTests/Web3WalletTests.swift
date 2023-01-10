import XCTest
import Combine

@testable import Auth
@testable import Web3Wallet

final class Web3WalletTests: XCTestCase {
    var web3WalletClient: Web3WalletClient!
    var authClient: AuthClientMock!
    var signClient: SignClientMock!
    var pairingClient: PairingClientMock!

    private var disposeBag = Set<AnyCancellable>()
    
    override func setUp() {
        authClient = AuthClientMock()
        signClient = SignClientMock()
        pairingClient = PairingClientMock()
        
        web3WalletClient = Web3WalletClientFactory.create(
            authClient: authClient,
            signClient: signClient,
            pairingClient: pairingClient
        )
    }
    
    func testSessionRequestCalled() {
        var success = false
        web3WalletClient.sessionRequestPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testAuthRequestCalled() {
        var success = false
        web3WalletClient.authRequestPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSessionProposalCalled() {
        var success = false
        web3WalletClient.sessionProposalPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSessionsCalled() {
        var success = false
        web3WalletClient.sessionsPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testApproveCalled() async {
        try! await web3WalletClient.approve(proposalId: "", namespaces: [:])
        XCTAssertTrue(signClient.approveCalled)
    }
    
    func testRejectSessionCalled() async {
        try! await web3WalletClient.reject(proposalId: "", reason: .userRejected)
        XCTAssertTrue(signClient.rejectCalled)
    }
    
    func testRejectAuthRequestCalled() async {
        try! await web3WalletClient.reject(requestId: .left(""))
        XCTAssertTrue(authClient.rejectCalled)
    }
    
    func testUpdateCalled() async {
        try! await web3WalletClient.update(topic: "", namespaces: [:])
        XCTAssertTrue(signClient.updateCalled)
    }
    
    func testExtendCalled() async {
        try! await web3WalletClient.extend(topic: "")
        XCTAssertTrue(signClient.extendCalled)
    }
    
    func testSignRespondCalled() async {
        try! await web3WalletClient.respond(
            topic: "",
            requestId: .left(""),
            response: RPCResult.response(AnyCodable(true))
        )
        XCTAssertTrue(signClient.respondCalled)
    }
    
    func testPairCalled() async {
        try! await web3WalletClient.pair(uri: WalletConnectURI(
            topic: "topic",
            symKey: "symKey",
            relay: RelayProtocolOptions(protocol: "", data: "")
        ))
        XCTAssertTrue(pairingClient.pairCalled)
    }
    
    func testDisconnectCalled() async {
        try! await web3WalletClient.disconnect(topic: "")
        XCTAssertTrue(signClient.disconnectCalled)
    }
    
    func testGetSessionsCalledAndNotEmpty() {
        let sessions = web3WalletClient.getSessions()
        XCTAssertEqual(1, sessions.count)
    }
    
    func testFormatMessageCalled() {
        let authPayload = AuthPayload(
            requestParams: RequestParams(
                domain: "service.invalid",
                chainId: "eip155:1",
                nonce: "32891756",
                aud: "https://service.invalid/login",
                nbf: nil,
                exp: nil,
                statement: "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
                requestId: nil,
                resources: [
                    "ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/",
                    "https://example.com/my-web2-claim.json"
                ]
            ),
            iat: "2021-09-30T16:25:24Z"
        )
        
        let formattedMessage = try! web3WalletClient.formatMessage(
            payload: authPayload,
            address: ""
        )
        XCTAssertEqual("formatted_message", formattedMessage)
    }
    
    func testAuthRespondCalled() async {
        let signature = CacaoSignature(t: .eip191, s: "0x438effc459956b57fcd9f3dac6c675f9cee88abf21acab7305e8e32aa0303a883b06dcbd956279a7a2ca21ffa882ff55cc22e8ab8ec0f3fe90ab45f306938cfa1b")
        let account = Account("eip155:56:0xe5EeF1368781911d265fDB6946613dA61915a501")!
        
        try! await web3WalletClient.respond(
            requestId: .left(""),
            signature: signature,
            from: account
        )
        XCTAssertTrue(authClient.respondCalled)
    }
    
    func testSignPendingRequestsCalledAndNotEmpty() async {
        let pendingRequests = web3WalletClient.getPendingRequests(topic: "")
        XCTAssertEqual(1, pendingRequests.count)
    }
    
    func testSessionRequestRecordCalledAndNotNil() async {
        let sessionRequestRecord = web3WalletClient.getSessionRequestRecord(id: .left(""))
        XCTAssertNotNil(sessionRequestRecord)
    }
    
    func testAuthPendingRequestsCalledAndNotEmpty() async {
        let account = Account("eip155:56:0xe5EeF1368781911d265fDB6946613dA61915a501")!
        let pendingRequests = try! web3WalletClient.getPendingRequests(account: account)
        XCTAssertEqual(1, pendingRequests.count)
    }
}
