import XCTest
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

func deriveTopic(publicKey: String, privateKey: AgreementPrivateKey) -> String {
    try! KeyManagementService.generateAgreementKey(from: privateKey, peerPublicKey: publicKey).derivedTopic()
}


final class PairingEngineTests: XCTestCase {
    
    var engine: PairingEngine!
    
    var networkingInteractor: MockedWCRelay!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    var proposalPayloadsStore: KeyValueStore<WCRequestSubscriptionPayload>!
    
    var topicGenerator: TopicGenerator!
    
    override func setUp() {
        networkingInteractor = MockedWCRelay()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
        proposalPayloadsStore = KeyValueStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: "")
        setupEngine()
    }
    
    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func setupEngine() {
        let meta = AppMetadata.stub()
        let logger = ConsoleLoggerMock()
        engine = PairingEngine(
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            pairingStore: storageMock,
            sessionToPairingTopic: KeyValueStore<String>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            metadata: meta,
            logger: logger,
            topicGenerator: topicGenerator.getTopic,
            proposalPayloadsStore: proposalPayloadsStore)
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
    
    func testReceiveProposal() {
        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        storageMock.setPairing(pairing)
        var sessionProposed = false
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        let request = WCRequest(method: .sessionPropose, params: .sessionPropose(proposal))
        let payload = WCRequestSubscriptionPayload(topic: topicA, wcRequest: request)
        engine.onSessionProposal = { _ in
            sessionProposed = true
        }
        networkingInteractor.wcRequestPublisherSubject.send(payload)
        XCTAssertNotNil(try! proposalPayloadsStore.get(key: proposal.proposer.publicKey), "Proposer must store proposal payload")
        XCTAssertTrue(sessionProposed)
    }
    
    func testRespondProposal() {
        // Client receives a proposal
        let topicA = String.generateTopic()
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        let request = WCRequest(method: .sessionPropose, params: .sessionPropose(proposal))
        let payload = WCRequestSubscriptionPayload(topic: topicA, wcRequest: request)
        networkingInteractor.wcRequestPublisherSubject.send(payload)
        let (topicB, _) = engine.approveProposal(proposerPubKey: proposal.proposer.publicKey, validating: SessionNamespace.stubDictionary())!
        
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicB), "Responder must store agreement key for topic B")
        XCTAssertEqual(networkingInteractor.didRespondOnTopic!, topicA, "Responder must respond on topic A")
    }
    
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
        
        var sessionTopic: String!
        
        engine.onProposeResponse = { topic, _ in
            sessionTopic = topic
        }
        networkingInteractor.onPairingResponse?(response)
        let privateKey = try! cryptoMock.getPrivateKey(for: proposal.proposer.publicKey)!
        let topicB = deriveTopic(publicKey: responder.publicKey, privateKey: privateKey)
        
        let storedPairing = storageMock.getPairing(forTopic: topicA)!

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
        networkingInteractor.onPairingResponse?(response)
        
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
        networkingInteractor.onPairingResponse?(response)
        
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
