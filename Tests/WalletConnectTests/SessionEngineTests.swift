import XCTest
@testable import WalletConnect

fileprivate extension Pairing {
    
    static func stub() -> Pairing {
        Pairing(topic: String.generateTopic()!, peer: nil)
    }
}

fileprivate extension SessionType.Permissions {
    
    static func stub() -> SessionType.Permissions {
        SessionType.Permissions(
            blockchain: SessionType.Blockchain(chains: []),
            jsonrpc: SessionType.JSONRPC(methods: []),
            notifications: SessionType.Notifications(types: [])
        )
    }
}

fileprivate extension WCRequest {
    
    var sessionProposal: SessionType.Proposal? {
        guard case .pairingPayload(let payload) = self.params else { return nil }
        return payload.request.params
    }
}

final class SessionEngineTests: XCTestCase {
    
    var engine: SessionEngine!

    var relayMock: MockedWCRelay!
    var subscriberMock: MockedSubscriber!
    var storageMock: SessionSequenceStorageMock!
    var cryptoMock: CryptoStorageProtocolMock!
    
    var topicGenerator: TopicGenerator!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        storageMock = SessionSequenceStorageMock()
        cryptoMock = CryptoStorageProtocolMock()
        topicGenerator = TopicGenerator()
        
        let meta = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        let logger = ConsoleLogger()
        engine = SessionEngine(
            relay: relayMock,
            crypto: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            isController: false,
            metadata: meta,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }

    override func tearDown() {
        relayMock = nil
        subscriberMock = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func testPropose() {
        let pairing = Pairing.stub()
        
        let topicB = pairing.topic
        let topicC = topicGenerator.topic
        
        let permissions = SessionType.Permissions.stub()
        let relayOptions = RelayProtocolOptions(protocol: "", params: nil)
        engine.proposeSession(settledPairing: pairing, permissions: permissions, relay: relayOptions)
        
        guard let publishTopic = relayMock.requests.first?.topic, let proposal = relayMock.requests.first?.request.sessionProposal else {
            XCTFail("Proposer must publish an approval request."); return
        }
        
        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey))
        XCTAssert(storageMock.hasSequence(forTopic: topicC)) // TODO: check state
        XCTAssert(subscriberMock.didSubscribe(to: topicC))
        XCTAssertEqual(publishTopic, topicB)
        XCTAssertEqual(proposal.topic, topicC)
        // TODO: check for agreement keys transpose
    }
    
    func testApprove() {
        
    }
    
    func testReceiveApprovalResponse() {
        
    }
}
