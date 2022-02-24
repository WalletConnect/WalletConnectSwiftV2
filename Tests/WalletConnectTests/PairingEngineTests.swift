import XCTest
@testable import WalletConnect
import TestingUtils
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
    
    func setupEngine(isController: Bool) {
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
    
//    func testApproveMultipleCallsThrottleOnSameURI() {
//        setupEngine(isController: true)
//        let uri = WalletConnectURI.stub()
//        for i in 1...10 {
//            if i == 1 {
//                XCTAssertNoThrow(try engine.approve(uri))
//            } else {
//                XCTAssertThrowsError(try engine.approve(uri))
//            }
//        }
//    }
//
}
