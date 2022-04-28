import XCTest
@testable import WalletConnect
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

func deriveTopic(publicKey: String, privateKey: AgreementPrivateKey) -> String {
    try! KeyManagementService.generateAgreementKey(from: privateKey, peerPublicKey: publicKey).derivedTopic()
}

final class PairingEngineTests: XCTestCase {
    
    var engine: PairingEngine!
    
    var relayMock: MockedWCRelay!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    var proposalPayloadsStore: KeyValueStore<WCRequestSubscriptionPayload>!
    
    var topicGenerator: TopicGenerator!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
        proposalPayloadsStore = KeyValueStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: "")
        setupEngine()
    }
    
    override func tearDown() {
        relayMock = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func setupEngine() {
        let meta = AppMetadata.stub()
        let logger = ConsoleLoggerMock()
        engine = PairingEngine(
            relay: relayMock,
            kms: cryptoMock,
            pairingStore: storageMock,
            sessionToPairingTopic: KeyValueStore<String>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            metadata: meta,
            logger: logger,
            topicGenerator: topicGenerator.getTopic,
            proposalPayloadsStore: proposalPayloadsStore)
    }
    
    func testPairMultipleTimesOnSameURIThrows() {
        let uri = WalletConnectURI.stub()
        for i in 1...10 {
            if i == 1 {
                XCTAssertNoThrow(try engine.pair(uri))
            } else {
                XCTAssertThrowsError(try engine.pair(uri))
            }
        }
    }
    
    func testCreate() {
        let uri = engine.create()!
        XCTAssert(cryptoMock.hasSymmetricKey(for: uri.topic), "Proposer must store the symmetric key matching the URI.")
        XCTAssert(storageMock.hasPairing(forTopic: uri.topic), "The engine must store a pairing after creating one")
        XCTAssert(relayMock.didSubscribe(to: uri.topic), "Proposer must subscribe to pairing topic.")
        XCTAssert(storageMock.getPairing(forTopic: uri.topic)?.active == false, "Recently created pairing must be inactive.")
    }
    
    func testPair() {
        let uri = WalletConnectURI.stub()
        let topic = uri.topic
        try! engine.pair(uri)
        XCTAssert(relayMock.didSubscribe(to: topic), "Responder must subscribe to pairing topic.")
        XCTAssert(cryptoMock.hasSymmetricKey(for: topic), "Responder must store the symmetric key matching the pairing topic")
        XCTAssert(storageMock.hasPairing(forTopic: topic), "The engine must store a pairing")
    }
    
    func testPropose() {
        let pairing = Pairing.stub()
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        engine.propose(pairingTopic: pairing.topic, relay: relayOptions) {_ in}
        
        guard let publishTopic = relayMock.requests.first?.topic,
              let proposal = relayMock.requests.first?.request.sessionProposal else {
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
        relayMock.wcRequestPublisherSubject.send(payload)
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
        relayMock.wcRequestPublisherSubject.send(payload)
        let topicB = engine.respondSessionPropose(proposal: proposal)!
        
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicB), "Responder must store agreement key for topic B")
        XCTAssertEqual(relayMock.didRespondOnTopic!, topicA, "Responder must respond on topic A")
    }
    
    func testHandleSessionProposeResponse() {
        let uri = engine.create()!
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        // Client proposes session
        engine.propose(pairingTopic: pairing.topic, blockchains: [], methods: [], events: [], relay: relayOptions){_ in}
        
        guard let request = relayMock.requests.first?.request,
              let proposal = relayMock.requests.first?.request.sessionProposal else {
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
        
        engine.onProposeResponse = { topic in
            sessionTopic = topic
        }
        relayMock.onPairingResponse?(response)
        let privateKey = try! cryptoMock.getPrivateKey(for: proposal.proposer.publicKey)!
        let topicB = deriveTopic(publicKey: responder.publicKey, privateKey: privateKey)
        
        let storedPairing = storageMock.getPairing(forTopic: topicA)!

        XCTAssert(storedPairing.active)
        XCTAssertEqual(topicB, sessionTopic, "Responder engine calls back with session topic")
    }
    
    func testSessionProposeError() {
        let uri = engine.create()!
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        // Client propose session
        engine.propose(pairingTopic: pairing.topic, blockchains: [], methods: [], events: [], relay: relayOptions){_ in}
        
        guard let request = relayMock.requests.first?.request,
              let proposal = relayMock.requests.first?.request.sessionProposal else {
                  XCTFail("Proposer must publish session proposal request"); return
              }
        
        let response = WCResponse.stubError(forRequest: request, topic: topicA)
        relayMock.onPairingResponse?(response)
        
        XCTAssert(relayMock.didUnsubscribe(to: pairing.topic), "Proposer must unsubscribe if pairing is inactive.")
        XCTAssertFalse(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must delete an inactive pairing.")
        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must delete symmetric key if pairing is inactive.")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
    }
    
    func testSessionProposeErrorOnActivePairing() {
        let uri = engine.create()!
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
        
        // Client propose session
        engine.propose(pairingTopic: pairing.topic, blockchains: [], methods: [], events: [], relay: relayOptions){_ in}
        
        guard let request = relayMock.requests.first?.request,
              let proposal = relayMock.requests.first?.request.sessionProposal else {
                  XCTFail("Proposer must publish session proposal request"); return
              }
        
        var storedPairing = storageMock.getPairing(forTopic: topicA)!
        storedPairing.activate()
        storageMock.setPairing(storedPairing)
        
        let response = WCResponse.stubError(forRequest: request, topic: topicA)
        relayMock.onPairingResponse?(response)
        
        XCTAssertFalse(relayMock.didUnsubscribe(to: pairing.topic), "Proposer must not unsubscribe if pairing is active.")
        XCTAssert(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must not delete an active pairing.")
        XCTAssert(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must not delete symmetric key if pairing is active.")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
    }

    func testPairingExpiration() {
        let uri = engine.create()!
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        storageMock.onPairingExpiration?(pairing)
        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: uri.topic))
        XCTAssert(relayMock.didUnsubscribe(to: uri.topic))
    }
}
