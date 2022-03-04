import XCTest
@testable import WalletConnect
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

func deriveTopic(publicKey: String, privateKey: AgreementPrivateKey) -> String {
    try! KeyManagementService.generateAgreementSecret(from: privateKey, peerPublicKey: publicKey).derivedTopic()
}

final class PairingEngineTests: XCTestCase {
    
    var engine: PairingEngine!
    
    var relayMock: MockedWCRelay!
    var subscriberMock: MockedSubscriber!
    var storageMock: PairingSequenceStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    var topicGenerator: TopicGenerator!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        storageMock = PairingSequenceStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
    }
    
    override func tearDown() {
        relayMock = nil
        subscriberMock = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        engine = nil
    }
    
    func setupEngine() {
        let meta = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        let logger = ConsoleLoggerMock()
        engine = PairingEngine(
            relay: relayMock,
            kms: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            metadata: meta,
            logger: logger,
            topicGenerator: topicGenerator.getTopic)
    }
    
        func testPairMultipleTimesOnSameURIThrows() {
            setupEngine()
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
        setupEngine()
        let uri = engine.create()!
        XCTAssert(cryptoMock.hasSymmetricKey(for: uri.topic), "Proposer must store the symmetric key matching the URI.")
        XCTAssert(storageMock.hasSequence(forTopic: uri.topic), "The engine must store a pairing after creating one")
        XCTAssert(subscriberMock.didSubscribe(to: uri.topic), "Proposer must subscribe to pairing topic.")
    }
    
    func testPair() {
        setupEngine()
        let uri = WalletConnectURI.stub()
        let topic = uri.topic
        try! engine.pair(uri)
        XCTAssert(subscriberMock.didSubscribe(to: topic), "Responder must subscribe to pairing topic.")
        XCTAssert(cryptoMock.hasSymmetricKey(for: topic), "Responder must store the symmetric key matching the pairing topic")
        XCTAssert(storageMock.hasSequence(forTopic: topic), "The engine must store a pairing")
    }
}
