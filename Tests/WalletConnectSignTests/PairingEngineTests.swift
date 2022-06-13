import XCTest
import Combine
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

func deriveTopic(publicKey: String, privateKey: AgreementPrivateKey) -> String {
    try! KeyManagementService.generateAgreementKey(from: privateKey, peerPublicKey: publicKey).derivedTopic()
}


final class PairingEngineTests: XCTestCase {
    
    var engine: PairingEngine!
    var approveEngine: ApproveEngine!
    
    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    var topicGenerator: TopicGenerator!
    var publishers = Set<AnyCancellable>()
    
    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
        setupEngines()
    }
    
    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
        approveEngine = nil
    }
    
    func setupEngines() {
        let meta = AppMetadata.stub()
        let logger = ConsoleLoggerMock()
        engine = PairingEngine(
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            pairingStore: storageMock,
            metadata: meta,
            logger: logger,
            topicGenerator: topicGenerator.getTopic
        )
        approveEngine = ApproveEngine(
            networkingInteractor: networkingInteractor,
            proposalPayloadsStore: .init(defaults: RuntimeKeyValueStorage(), identifier: ""),
            sessionToPairingTopic: CodableStore<String>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            metadata: meta,
            kms: cryptoMock,
            logger: logger,
            pairingStore: storageMock,
            sessionStore: WCSessionStorageMock()
        )
    }
    
    func testCreate() async {
        let uri = try! await engine.create()
        XCTAssert(cryptoMock.hasSymmetricKey(for: uri.topic), "Proposer must store the symmetric key matching the URI.")
        XCTAssert(storageMock.hasPairing(forTopic: uri.topic), "The engine must store a pairing after creating one")
        XCTAssert(networkingInteractor.didSubscribe(to: uri.topic), "Proposer must subscribe to pairing topic.")
        XCTAssert(storageMock.getPairing(forTopic: uri.topic)?.active == false, "Recently created pairing must be inactive.")
    }
    
    func testPropose() async {
        let pairing = Pairing.stub()
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        // FIXME: namespace stub
        try! await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
        
        guard let publishTopic = networkingInteractor.requests.first?.topic,
              let proposal = networkingInteractor.requests.first?.request.sessionProposal else {
                  XCTFail("Proposer must publish a proposal request."); return
              }
        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must store the private key matching the public key sent through the proposal.")
        XCTAssertEqual(publishTopic, topicA)
    }
    
    @MainActor
    func testHandleSessionProposeResponse() async {
        let uri = try! await engine.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        // Client proposes session
        // FIXME: namespace stub
        try! await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
        
        guard let request = networkingInteractor.requests.first?.request,
              let proposal = networkingInteractor.requests.first?.request.sessionProposal else {
                  XCTFail("Proposer must publish session proposal request"); return
              }
        
        // Client receives proposal response response
        let responder = Participant.stub()
        let proposalResponse = SessionType.ProposeResponse(relay: relayOptions, responderPublicKey: responder.publicKey)
        
        let jsonRpcResponse = JSONRPCResponse<AnyCodable>(id: request.id, result: AnyCodable.decoded(proposalResponse))
        let response = WCResponse(topic: topicA,
                                  chainId: nil,
                                  requestMethod: request.method,
                                  requestParams: request.params,
                                  result: .response(jsonRpcResponse))

        networkingInteractor.responsePublisherSubject.send(response)
        let privateKey = try! cryptoMock.getPrivateKey(for: proposal.proposer.publicKey)!
        let topicB = deriveTopic(publicKey: responder.publicKey, privateKey: privateKey)
        let storedPairing = storageMock.getPairing(forTopic: topicA)!
        let sessionTopic = networkingInteractor.subscriptions.last!

        XCTAssertTrue(networkingInteractor.didCallSubscribe)
        XCTAssert(storedPairing.active)
        XCTAssertEqual(topicB, sessionTopic, "Responder engine calls back with session topic")
    }
    
    func testSessionProposeError() async {
        let uri = try! await engine.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        // Client propose session
        // FIXME: namespace stub
        try! await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
        
        guard let request = networkingInteractor.requests.first?.request,
              let proposal = networkingInteractor.requests.first?.request.sessionProposal else {
                  XCTFail("Proposer must publish session proposal request"); return
              }
        
        let response = WCResponse.stubError(forRequest: request, topic: topicA)
        networkingInteractor.responsePublisherSubject.send(response)
        
        XCTAssert(networkingInteractor.didUnsubscribe(to: pairing.topic), "Proposer must unsubscribe if pairing is inactive.")
        XCTAssertFalse(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must delete an inactive pairing.")
        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must delete symmetric key if pairing is inactive.")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
    }
    
    func testSessionProposeErrorOnActivePairing() async {
        let uri = try! await engine.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        // Client propose session
        // FIXME: namespace stub
        try? await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
        
        guard let request = networkingInteractor.requests.first?.request,
              let proposal = networkingInteractor.requests.first?.request.sessionProposal else {
                  XCTFail("Proposer must publish session proposal request"); return
              }
        
        var storedPairing = storageMock.getPairing(forTopic: topicA)!
        storedPairing.activate()
        storageMock.setPairing(storedPairing)
        
        let response = WCResponse.stubError(forRequest: request, topic: topicA)
        networkingInteractor.responsePublisherSubject.send(response)
        
        XCTAssertFalse(networkingInteractor.didUnsubscribe(to: pairing.topic), "Proposer must not unsubscribe if pairing is active.")
        XCTAssert(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must not delete an active pairing.")
        XCTAssert(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must not delete symmetric key if pairing is active.")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
    }

    func testPairingExpiration() async {
        let uri = try! await engine.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        storageMock.onPairingExpiration?(pairing)
        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: uri.topic))
        XCTAssert(networkingInteractor.didUnsubscribe(to: uri.topic))
    }
}
