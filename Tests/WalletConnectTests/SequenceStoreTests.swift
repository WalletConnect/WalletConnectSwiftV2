import XCTest
@testable import WalletConnect

struct WCSequenceStub: WCSequence, Equatable {
    let topic: String
    let expiryDate: Date
}

final class TimeTraveler {
    
    private(set) var referenceDate = Date()
    
    func generateDate() -> Date {
        return referenceDate
    }
    
    func travel(by timeInterval: TimeInterval) {
        referenceDate = referenceDate.addingTimeInterval(timeInterval)
    }
}

final class SequenceStoreTests: XCTestCase {
    
    var sut: SequenceStore<WCSequenceStub>!
    
    var storageFake: RuntimeKeyValueStorage!
    
    var timeTraveler: TimeTraveler!
    
    let defaultTime = TimeInterval(Time.day)
    
    override func setUp() {
        timeTraveler = TimeTraveler()
        storageFake = RuntimeKeyValueStorage()
        sut = SequenceStore<WCSequenceStub>(storage: storageFake, dateInitializer: timeTraveler.generateDate)
    }
    
    override func tearDown() {
        timeTraveler = nil
        storageFake = nil
        sut = nil
    }
    
    private func stubSequence() -> WCSequenceStub {
        WCSequenceStub(
            topic: String.generateTopic()!,
            expiryDate: timeTraveler.referenceDate.addingTimeInterval(defaultTime)
        )
    }
    
    func testRoundTrip() {
        let sequence = stubSequence()
        try? sut.setSequence(sequence)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)
        XCTAssertEqual(retrieved, sequence)
    }
    
    func testExpiration() {
        let sequence = stubSequence()
        var expiredTopic: String? = nil
        sut.onSequenceExpiration = { expiredTopic = $0 }
        
        try? sut.setSequence(sequence)
        timeTraveler.travel(by: defaultTime)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)
        
        XCTAssertNil(retrieved)
        XCTAssertEqual(expiredTopic, sequence.topic)
    }
    
    func testDelete() {
        
    }
}
