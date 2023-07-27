import XCTest
import Combine

@testable import Auth
@testable import Web3Wallet


import JSONRPC
import WalletConnectPairing
import WalletConnectNetworking
@testable import WalletConnectUtils
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS

final class Web3WalletTests: XCTestCase {
    var web3WalletClient: Web3WalletClient!
    var authClient: AuthClientMock!
    var signClient: SignClientMock!
    var pairingClient: PairingClientMock!
    var echoClient: EchoClientMock!
    
    var approveEngine: ApproveEngine!
    var sessionEngine: SessionEngine!
    var sut: WalletRequestSubscriber!
    
    var metadata: AppMetadata!
    var networkingInteractor: NetworkingInteractorMock!
    var cryptoMock: KeyManagementServiceMock!
    var pairingStorageMock: WCPairingStorageMock!
    var sessionStorageMock: WCSessionStorageMock!
    var pairingRegisterer: PairingRegistererMock<SessionProposal>!
    var proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>!
    var sessionTopicToProposal: CodableStore<Session.Proposal>!

    private var disposeBag = Set<AnyCancellable>()
    
    override func setUp() {
        authClient = AuthClientMock()
        signClient = SignClientMock()
        pairingClient = PairingClientMock()
        echoClient = EchoClientMock()
        
        metadata = AppMetadata.stub()
        networkingInteractor = NetworkingInteractorMock()
        cryptoMock = KeyManagementServiceMock()
        pairingStorageMock = WCPairingStorageMock()
        sessionStorageMock = WCSessionStorageMock()
        pairingRegisterer = PairingRegistererMock()
        proposalPayloadsStore = CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>(defaults: RuntimeKeyValueStorage(), identifier: "")
        sessionTopicToProposal = CodableStore<Session.Proposal>(defaults: RuntimeKeyValueStorage(), identifier: "")
        
        approveEngine = ApproveEngine(
            networkingInteractor: networkingInteractor,
            proposalPayloadsStore: proposalPayloadsStore,
            sessionTopicToProposal: sessionTopicToProposal,
            pairingRegisterer: pairingRegisterer,
            metadata: metadata,
            kms: cryptoMock,
            logger: ConsoleLoggerMock(),
            pairingStore: pairingStorageMock,
            sessionStore: sessionStorageMock,
            verifyClient: VerifyClientMock()
        )
        
        let walletErrorResponder = WalletErrorResponder(networkingInteractor: networkingInteractor, logger: ConsoleLoggerMock(), kms: KeyManagementServiceMock(), rpcHistory: RPCHistory(keyValueStore: CodableStore(defaults: RuntimeKeyValueStorage(), identifier: "")))
        sut = WalletRequestSubscriber(networkingInteractor: networkingInteractor,
                                      logger: ConsoleLoggerMock(),
                                      kms: KeyManagementServiceMock(),
                                      walletErrorResponder: walletErrorResponder,
                                      pairingRegisterer: pairingRegisterer,
                                      verifyClient: VerifyClientMock())
        
        sessionEngine = SessionEngine(
            networkingInteractor: networkingInteractor,
            historyService: HistoryService(
                history: RPCHistory(
                    keyValueStore: .init(
                        defaults: RuntimeKeyValueStorage(),
                        identifier: ""
                    )
                )
            ),
            verifyClient: VerifyClientMock(),
            kms: cryptoMock,
            sessionStore: sessionStorageMock,
            logger: ConsoleLoggerMock()
        )
        
        web3WalletClient = Web3WalletClientFactory.create(
            authClient: authClient,
            signClient: signClient,
            pairingClient: pairingClient,
            echoClient: echoClient,
            networkingInteractor: networkingInteractor
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
    
    func testSocketConnectionStatusCalled() {
        var success = false
        web3WalletClient.socketConnectionStatusPublisher.sink { value in
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
    
    func testSessionSettleCalled() {
        var success = false
        web3WalletClient.sessionSettlePublisher.sink { value in
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
    
    func testSessionDeleteCalled() {
        var success = false
        web3WalletClient.sessionDeletePublisher.sink { value in
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
    
    func testSessionResponseCalled() {
        var success = false
        web3WalletClient.sessionResponsePublisher.sink { value in
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
    
    func testReceivedSessionProposalStateCalled() {
        let proposalReceivedExpectation = expectation(description: "Wallet expects to receive a proposal")

        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        
        pairingStorageMock.setPairing(pairing)
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)

        var walletConnectState: WalletConnectState?
        approveEngine.onSessionProposal = { _, _ in
            proposalReceivedExpectation.fulfill()
        }
        web3WalletClient.walletConnectStatePublisher.sink { value in
            walletConnectState = value
        }
        .store(in: &disposeBag)
        pairingRegisterer.subject.send(RequestSubscriptionPayload(id: RPCID("id"), topic: topicA, request: proposal, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil))

        wait(for: [proposalReceivedExpectation], timeout: 0.1)
        XCTAssertTrue(walletConnectState == .received)
    }
    
    func testReceivedSessionRequestStateCalled() {
        let requestReceivedExpectation = expectation(description: "Wallet expects to receive a proposal")

        let session = WCSession.stub(
            namespaces: [
                "eip": SessionNamespace(
                    accounts: [Account(blockchain: Blockchain(namespace: "eip", reference: "1")!, address: "0x000")!],
                    methods: ["personal_sign"],
                    events: []
                )
            ]
        )
        let topicA = session.topic
        
        sessionStorageMock.setSession(session)
        let request = RPCRequest.stubRequest(method: "personal_sign", chainId: Blockchain(namespace: "eip", reference: "1")!)

        var walletConnectState: WalletConnectState?
        sessionEngine.onSessionRequest = { _, _ in
            requestReceivedExpectation.fulfill()
        }
        web3WalletClient.walletConnectStatePublisher.sink { value in
            walletConnectState = value
        }
        .store(in: &disposeBag)
        networkingInteractor.requestPublisherSubject.send((topic: topicA, request: request, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil))

        wait(for: [requestReceivedExpectation], timeout: 0.1)
        XCTAssertTrue(walletConnectState == .received)
    }
    
    func testReceivedAuthRequestStateCalled() {
        let iat = ISO8601DateFormatter().string(from: Date())
        let expectedPayload = AuthPayload(requestParams: .stub(), iat: iat)
        let expectedRequestId: RPCID = RPCID(1234)
        let messageExpectation = expectation(description: "receives formatted message")

        var requestId: RPCID!
        var requestPayload: AuthPayload!
        sut.onRequest = { result in
            requestId = result.request.id
            requestPayload = result.request.payload
            messageExpectation.fulfill()
        }

        let payload = RequestSubscriptionPayload<AuthRequestParams>(id: expectedRequestId, topic: "123", request: AuthRequestParams.stub(id: expectedRequestId, iat: iat), decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil)

        pairingRegisterer.subject.send(payload)

        wait(for: [messageExpectation], timeout: defaultTimeout)
        XCTAssertTrue(pairingRegisterer.isActivateCalled)
        XCTAssertEqual(requestPayload, expectedPayload)
        XCTAssertEqual(requestId, expectedRequestId)
        
//        let requestReceivedExpectation = expectation(description: "Wallet expects to receive a proposal")
//
//        let session = WCSession.stub(
//            namespaces: [
//                "eip": SessionNamespace(
//                    accounts: [Account(blockchain: Blockchain(namespace: "eip", reference: "1")!, address: "0x000")!],
//                    methods: ["personal_sign"],
//                    events: []
//                )
//            ]
//        )
//        let topicA = session.topic
//
//        sessionStorageMock.setSession(session)
//        let request = RPCRequest.stubRequest(method: "personal_sign", chainId: Blockchain(namespace: "eip", reference: "1")!)
//
//        var walletConnectState: WalletConnectStatus?
//        sessionEngine.onSessionRequest = { _, _ in
//            requestReceivedExpectation.fulfill()
//        }
//        web3WalletClient.walletConnectStatePublisher.sink { value in
//            walletConnectState = value
//        }
//        .store(in: &disposeBag)
//        networkingInteractor.requestPublisherSubject.send((topic: topicA, request: request, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil))
//
//        wait(for: [requestReceivedExpectation], timeout: 0.1)
//        XCTAssertTrue(walletConnectState == .received)
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
    
    func testDisconnectPairingCalled() async {
        try! await web3WalletClient.disconnectPairing(topic: "topic")
        XCTAssertTrue(pairingClient.disconnectPairingCalled)
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
        let pendingRequests = try! web3WalletClient.getPendingRequests()
        XCTAssertEqual(1, pendingRequests.count)
    }
    
    func testCleanupCalled() async {
        try! await web3WalletClient.cleanup()
        XCTAssertTrue(signClient.cleanupCalled)
    }
    
    func testGetPairingsNotEmpty() async {
        XCTAssertEqual(1, web3WalletClient.getPairings().count)
    }
    
    func testEchoClientRegisterCalled() async {
        try! await echoClient.register(deviceToken: Data())
        XCTAssertTrue(echoClient.registedCalled)
        echoClient.registedCalled = false
        try! await echoClient.register(deviceToken: "")
        XCTAssertTrue(echoClient.registedCalled)
    }
}

@testable import WalletConnectSign
import Foundation

final class WCSessionStorageMock: WCSessionStorage {

    var onSessionsUpdate: (() -> Void)?
    var onSessionExpiration: ((WCSession) -> Void)?

    private(set) var sessions: [String: WCSession] = [:]

    func hasSession(forTopic topic: String) -> Bool {
        sessions[topic] != nil
    }

    @discardableResult
    func setSessionIfNewer(_ session: WCSession) -> Bool {
        guard isNeedToReplace(session) else { return false }
        sessions[session.topic] = session
        return true
    }

    func setSession(_ session: WCSession) {
        sessions[session.topic] = session
    }

    func getSession(forTopic topic: String) -> WCSession? {
        return sessions[topic]
    }

    func getAll() -> [WCSession] {
        Array(sessions.values)
    }

    func delete(topic: String) {
        sessions[topic] = nil
    }

    func deleteAll() {
        sessions = [:]
    }
}

// MARK: Privates

private extension WCSessionStorageMock {

    func isNeedToReplace(_ session: WCSession) -> Bool {
        guard let old = getSession(forTopic: session.topic) else { return true }
        return session.timestamp > old.timestamp
    }
}

extension Pairing {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), topic: String = String.generateTopic()) -> Pairing {
        Pairing(topic: topic, peer: nil, expiryDate: expiryDate)
    }
}

extension WCPairing {
    static func stub(expiryDate: Date = Date(timeIntervalSinceNow: 10000), isActive: Bool = true, topic: String = String.generateTopic()) -> WCPairing {
        WCPairing(topic: topic, relay: RelayProtocolOptions.stub(), peerMetadata: AppMetadata.stub(), isActive: isActive, expiryDate: expiryDate)
    }
}

extension ProposalNamespace {
    static func stubDictionary() -> [String: ProposalNamespace] {
        return [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["method"],
                events: ["event"])
        ]
    }
}

extension SessionNamespace {
    static func stubDictionary() -> [String: SessionNamespace] {
        return [
            "eip155": SessionNamespace(
                accounts: [Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!],
                methods: ["method"],
                events: ["event"])
        ]
    }
}

extension Participant {
    static func stub(publicKey: String = AgreementPrivateKey().publicKey.hexRepresentation) -> Participant {
        Participant(publicKey: publicKey, metadata: AppMetadata.stub())
    }
}

extension AgreementPeer {
    static func stub(publicKey: String = AgreementPrivateKey().publicKey.hexRepresentation) -> AgreementPeer {
        AgreementPeer(publicKey: publicKey)
    }
}

extension RPCRequest {

    static func stubUpdateNamespaces(namespaces: [String: SessionNamespace] = SessionNamespace.stubDictionary()) -> RPCRequest {
        return RPCRequest(method: SessionUpdateProtocolMethod().method, params: SessionType.UpdateParams(namespaces: namespaces))
    }

    static func stubUpdateExpiry(expiry: Int64) -> RPCRequest {
        return RPCRequest(method: SessionExtendProtocolMethod().method, params: SessionType.UpdateExpiryParams(expiry: expiry))
    }

    static func stubSettle() -> RPCRequest {
        return RPCRequest(method: SessionSettleProtocolMethod().method, params: SessionType.SettleParams.stub())
    }

    static func stubRequest(method: String, chainId: Blockchain, expiry: UInt64? = nil) -> RPCRequest {
        let params = SessionType.RequestParams(
            request: SessionType.RequestParams.Request(method: method, params: AnyCodable(EmptyCodable()), expiry: expiry),
            chainId: chainId)
        return RPCRequest(method: SessionRequestProtocolMethod().method, params: params)
    }
}

extension SessionProposal {
    static func stub(proposerPubKey: String = "") -> SessionProposal {
        let relayOptions = RelayProtocolOptions(protocol: "irn", data: nil)
        return SessionType.ProposeParams(
            relays: [relayOptions],
            proposer: Participant(publicKey: proposerPubKey, metadata: AppMetadata.stub()),
            requiredNamespaces: ProposalNamespace.stubDictionary(),
            optionalNamespaces: ProposalNamespace.stubDictionary(),
            sessionProperties: ["caip154-mandatory": "true"]
        )
    }
}

extension RPCResponse {
    static func stubError(forRequest request: RPCRequest) -> RPCResponse {
        return RPCResponse(matchingRequest: request, error: JSONRPCError(code: 0, message: ""))
    }
}

extension SessionType.SettleParams {
    static func stub() -> SessionType.SettleParams {
        return SessionType.SettleParams(
            relay: RelayProtocolOptions.stub(),
            controller: Participant.stub(),
            namespaces: SessionNamespace.stubDictionary(),
            sessionProperties: nil,
            expiry: Int64(Date.distantFuture.timeIntervalSince1970))
    }
}

private extension Request {

    static func stub(expiry: UInt64? = nil) -> Request {
        return Request(
            topic: "topic",
            method: "method",
            params: AnyCodable("params"),
            chainId: Blockchain("eip155:1")!,
            expiry: expiry
        )
    }
}

extension WCSession {
    static func stub(
        topic: String = .generateTopic(),
        isSelfController: Bool = false,
        expiryDate: Date = Date.distantFuture,
        selfPrivateKey: AgreementPrivateKey = AgreementPrivateKey(),
        namespaces: [String: SessionNamespace] = [:],
        sessionProperties: [String: String] = [:],
        requiredNamespaces: [String: ProposalNamespace] = [:],
        acknowledged: Bool = true,
        timestamp: Date = Date()
    ) -> WCSession {
            let peerKey = selfPrivateKey.publicKey.hexRepresentation
            let selfKey = AgreementPrivateKey().publicKey.hexRepresentation
            let controllerKey = isSelfController ? selfKey : peerKey
            return WCSession(
                topic: topic,
                pairingTopic: "",
                timestamp: timestamp,
                relay: RelayProtocolOptions.stub(),
                controller: AgreementPeer(publicKey: controllerKey),
                selfParticipant: Participant.stub(publicKey: selfKey),
                peerParticipant: Participant.stub(publicKey: peerKey),
                namespaces: namespaces,
                sessionProperties: sessionProperties,
                requiredNamespaces: requiredNamespaces,
                events: [],
                accounts: Account.stubSet(),
                acknowledged: acknowledged,
                expiry: Int64(expiryDate.timeIntervalSince1970))
        }
}

extension Account {
    static func stubSet() -> Set<Account> {
        return Set(["chainstd:0:0", "chainstd:1:1", "chainstd:2:2"].map { Account($0)! })
    }
}

extension RequestParams {
    static func stub(domain: String = "service.invalid",
                     chainId: String = "eip155:1",
                     nonce: String = "32891756",
                     aud: String = "https://service.invalid/login",
                     nbf: String? = nil,
                     exp: String? = nil,
                     statement: String? = "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
                     requestId: String? = nil,
                     resources: [String]? = ["ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/", "https://example.com/my-web2-claim.json"]) -> RequestParams {
        return RequestParams(domain: domain,
                             chainId: chainId,
                             nonce: nonce,
                             aud: aud,
                             nbf: nbf,
                             exp: exp,
                             statement: statement,
                             requestId: requestId,
                             resources: resources)
    }
}
