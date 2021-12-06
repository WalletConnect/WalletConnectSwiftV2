
import Foundation
import XCTest
@testable import WalletConnect

final class SessionSequenceStorageMock: SessionSequenceStorage {
    
    var onSequenceExpiration: ((String, String) -> Void)?
    
    func hasSequence(forTopic topic: String) -> Bool {
        fatalError()
    }
    
    func setSequence(_ sequence: SessionSequence) {
        
    }
    
    func getSequence(forTopic topic: String) throws -> SessionSequence? {
        fatalError()
    }
    
    func getAll() -> [SessionSequence] {
        fatalError()
    }
    
    func delete(topic: String) {
        
    }
}

final class SessionEngineTests: XCTestCase {
    
    var engine: SessionEngine!

    var relayMock: MockedWCRelay!
    var subscriberMock: MockedSubscriber!
    var storageMock: SessionSequenceStorageMock!
    var cryptoMock: CryptoStorageProtocolMock!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        subscriberMock = MockedSubscriber()
        storageMock = SessionSequenceStorageMock()
        cryptoMock = CryptoStorageProtocolMock()
        
        let meta = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        let logger = ConsoleLogger()
        engine = SessionEngine(
            relay: relayMock,
            crypto: cryptoMock,
            subscriber: subscriberMock,
            sequencesStore: storageMock,
            isController: false,
            metadata: meta,
            logger: logger)
    }

    override func tearDown() {
        relayMock = nil
        subscriberMock = nil
        storageMock = nil
        cryptoMock = nil
        engine = nil
    }
    
    func testPropose() {
        
    }
    
    func testApprove() {
        
    }
    
    func testReceiveApprovalResponse() {
        
    }
}
