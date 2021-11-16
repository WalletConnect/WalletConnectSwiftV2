import XCTest
@testable import WalletConnect

struct ExpirableSequenceStub: ExpirableSequence, Equatable {
    let topic: String
    let expiryDate: Date
}

final class SequenceStoreTests: XCTestCase {
    
    var sut: SequenceStore<ExpirableSequenceStub>!
    
    var storageFake: RuntimeKeyValueStorage!
    
    var timeTraveler: TimeTraveler!
    
    let defaultTime = TimeInterval(Time.day)
    
    override func setUp() {
        timeTraveler = TimeTraveler()
        storageFake = RuntimeKeyValueStorage()
        sut = SequenceStore<ExpirableSequenceStub>(storage: storageFake, dateInitializer: timeTraveler.generateDate)
        sut.onSequenceExpiration = { _ in
            XCTFail("Unexpected expiration call")
        }
    }
    
    override func tearDown() {
        timeTraveler = nil
        storageFake = nil
        sut = nil
    }
    
    private func stubSequence(expiry: TimeInterval? = nil) -> ExpirableSequenceStub {
        ExpirableSequenceStub(
            topic: String.generateTopic()!,
            expiryDate: timeTraveler.referenceDate.addingTimeInterval(expiry ?? defaultTime)
        )
    }
    
    // MARK: - CRUD Tests
    
    func testRoundTrip() {
        let sequence = stubSequence()
        try? sut.setSequence(sequence)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)
        XCTAssertTrue(sut.hasSequence(forTopic: sequence.topic))
        XCTAssertEqual(retrieved, sequence)
    }
    
    func testGetAll() {
        let sequenceArray = (1...10).map { _ -> ExpirableSequenceStub in
            let sequence = stubSequence()
            try? sut.setSequence(sequence)
            return sequence
        }
        let retrieved = sut.getAll()
        XCTAssertEqual(retrieved.count, sequenceArray.count)
        sequenceArray.forEach {
            XCTAssert(retrieved.contains($0))
        }
    }
    
    func testUpdate() {
        let initialSequence = stubSequence()
        let updatedSequence = stubSequence()
        try? sut.setSequence(initialSequence)
        try? sut.update(sequence: updatedSequence, onTopic: initialSequence.topic)
        let initialRetrieved = try? sut.getSequence(forTopic: initialSequence.topic)
        let updatedRetrieved = try? sut.getSequence(forTopic: updatedSequence.topic)
        XCTAssertNil(initialRetrieved)
        XCTAssertEqual(updatedRetrieved, updatedSequence)
    }
    
    func testDelete() {
        let sequence = stubSequence()
        try? sut.setSequence(sequence)
        sut.delete(topic: sequence.topic)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)
        XCTAssertFalse(sut.hasSequence(forTopic: sequence.topic))
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Expiration Tests
    
    func testHasSequenceExpiration() {
        let sequence = stubSequence()
        var expiredTopic: String? = nil
        sut.onSequenceExpiration = { expiredTopic = $0 }
        
        try? sut.setSequence(sequence)
        timeTraveler.travel(by: defaultTime)
        
        XCTAssertFalse(sut.hasSequence(forTopic: sequence.topic))
        XCTAssertEqual(expiredTopic, sequence.topic)
    }
    
    func testGetSequenceExpiration() {
        let sequence = stubSequence()
        var expiredTopic: String? = nil
        sut.onSequenceExpiration = { expiredTopic = $0 }
        
        try? sut.setSequence(sequence)
        timeTraveler.travel(by: defaultTime)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)
        
        XCTAssertNil(retrieved)
        XCTAssertEqual(expiredTopic, sequence.topic)
    }
    
    func testGetAllExpiration() {
        let sequenceCount = 10
        var expiredCount = 0
        sut.onSequenceExpiration = { _ in expiredCount += 1 }
        (1...sequenceCount).forEach { _ in
            let sequence = stubSequence()
            try? sut.setSequence(sequence)
        }
        
        timeTraveler.travel(by: defaultTime)
        let retrieved = sut.getAll()
        
        XCTAssert(retrieved.isEmpty)
        XCTAssert(expiredCount == sequenceCount)
    }
    
    func testGetAllPartialExpiration() {
        var expiredCount = 0
        sut.onSequenceExpiration = { _ in expiredCount += 1 }
        let persistentCount = 5
        let expirableCount = 3
        (1...persistentCount).forEach { _ in
            let sequence = stubSequence(expiry: defaultTime + 1)
            try? sut.setSequence(sequence)
        }
        (1...expirableCount).forEach { _ in
            let sequence = stubSequence()
            try? sut.setSequence(sequence)
        }
        
        timeTraveler.travel(by: defaultTime)
        let retrievedCount = sut.getAll().count
        
        XCTAssert(retrievedCount == persistentCount)
        XCTAssert(expiredCount == expirableCount)
    }
}
