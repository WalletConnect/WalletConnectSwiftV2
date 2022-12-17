import XCTest
import WalletConnectUtils
@testable import WalletConnectSign

struct ExpirableSequenceStub: SequenceObject, Equatable {
    let topic: String
    let publicKey: String?
    let expiryDate: Date

    var timestamp: Date {
        return .distantPast
    }

    func isNewer(than date: Date) -> Bool {
        return true
    }

    func isExpired(now: Date) -> Bool {
        return now >= expiryDate
    }
}

final class SequenceStoreTests: XCTestCase {

    var sut: SequenceStore<ExpirableSequenceStub>!

    var storageFake: RuntimeKeyValueStorage!

    var timeTraveler: TimeTraveler!

    let defaultTime = TimeInterval(Time.day)

    override func setUp() {
        timeTraveler = TimeTraveler()
        sut = makeStore("test")
        sut.onSequenceExpiration = { _ in
            XCTFail("Unexpected expiration call")
        }
    }

    override func tearDown() {
        timeTraveler = nil
        storageFake = nil
        sut = nil
    }

    private func makeStore(_ identifier: String) -> SequenceStore<ExpirableSequenceStub> {
        return SequenceStore<ExpirableSequenceStub>(
            store: .init(defaults: RuntimeKeyValueStorage(), identifier: identifier),
            dateInitializer: timeTraveler.generateDate
        )
    }

    private func stubSequence(expiry: TimeInterval? = nil) -> ExpirableSequenceStub {
        ExpirableSequenceStub(
            topic: String.generateTopic(),
            publicKey: "0x",
            expiryDate: timeTraveler.referenceDate.addingTimeInterval(expiry ?? defaultTime)
        )
    }

    // MARK: - CRUD Tests

    func testRoundTrip() {
        let sequence = stubSequence()
        sut.setSequence(sequence)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)
        XCTAssertTrue(sut.hasSequence(forTopic: sequence.topic))
        XCTAssertEqual(retrieved, sequence)
    }

    func testGetAll() {
        let sequenceArray = (1...10).map { _ -> ExpirableSequenceStub in
            let sequence = stubSequence()
            sut.setSequence(sequence)
            return sequence
        }
        let retrieved = sut.getAll()
        XCTAssertEqual(retrieved.count, sequenceArray.count)
        sequenceArray.forEach {
            XCTAssert(retrieved.contains($0))
        }
    }

    func testDelete() {
        let sequence = stubSequence()
        sut.setSequence(sequence)
        sut.delete(topic: sequence.topic)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)
        XCTAssertFalse(sut.hasSequence(forTopic: sequence.topic))
        XCTAssertNil(retrieved)
    }

    func testDeleteAll() {
        let sequence = stubSequence()
        sut.setSequence(sequence)

        let sut2 = makeStore("test2")
        sut2.setSequence(sequence)

        XCTAssertFalse(sut.getAll().isEmpty)
        XCTAssertFalse(sut2.getAll().isEmpty)

        sut.deleteAll()

        XCTAssertTrue(sut.getAll().isEmpty)
        XCTAssertFalse(sut2.getAll().isEmpty)
    }

    func testUpdateHandler() {
        let expectation = expectation(description: "TestUpdateHandler")
        expectation.expectedFulfillmentCount = 3
        let sequence = stubSequence()

        sut.onSequenceUpdate = {
            expectation.fulfill()
        }

        sut.setSequence(sequence)
        sut.delete(topic: sequence.topic)
        sut.deleteAll()

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Expiration Tests

    func testHasSequenceExpiration() {
        let sequence = stubSequence()
        var expired: ExpirableSequenceStub?
        sut.onSequenceExpiration = { expired = $0 }

        sut.setSequence(sequence)
        timeTraveler.travel(by: defaultTime)

        XCTAssertFalse(sut.hasSequence(forTopic: sequence.topic))
        XCTAssertEqual(expired?.topic, sequence.topic)
    }

    func testGetSequenceExpiration() {
        let sequence = stubSequence()
        var expired: ExpirableSequenceStub?
        sut.onSequenceExpiration = { expired = $0 }

        sut.setSequence(sequence)
        timeTraveler.travel(by: defaultTime)
        let retrieved = try? sut.getSequence(forTopic: sequence.topic)

        XCTAssertNil(retrieved)
        XCTAssertEqual(expired?.topic, sequence.topic)
    }

    func testGetAllExpiration() {
        let sequenceCount = 10
        var expiredCount = 0
        sut.onSequenceExpiration = { _ in expiredCount += 1 }
        (1...sequenceCount).forEach { _ in
            let sequence = stubSequence()
            sut.setSequence(sequence)
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
            sut.setSequence(sequence)
        }
        (1...expirableCount).forEach { _ in
            let sequence = stubSequence()
            sut.setSequence(sequence)
        }

        timeTraveler.travel(by: defaultTime)
        let retrievedCount = sut.getAll().count

        XCTAssert(retrievedCount == persistentCount)
        XCTAssert(expiredCount == expirableCount)
    }
}
