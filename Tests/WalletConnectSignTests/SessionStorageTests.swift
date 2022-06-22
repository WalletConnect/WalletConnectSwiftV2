import Foundation
import XCTest
@testable import WalletConnectSign
import WalletConnectUtils

final class SessionStorageTests: XCTestCase {

    var sut: SessionStorage!

    override func setUp() {
        sut = SessionStorage(storage: .init(store: .init(
            defaults: RuntimeKeyValueStorage(),
            identifier: "")
        ))
    }

    func testUpdateSessionFailedByTimestamp() {
        let timestamp = Date()
        let old = WCSession.stub(timestamp: timestamp)

        XCTAssertTrue(sut.setSessionIfNewer(old))
        XCTAssertEqual(sut.getAll(), [old])

        let new = WCSession.stub(topic: old.topic, timestamp: timestamp)

        XCTAssertFalse(sut.setSessionIfNewer(new))
    }

    func testUpdateSessionSucceedByTimestamp() {
        let old = WCSession.stub(timestamp: Date())

        XCTAssertTrue(sut.setSessionIfNewer(old))
        XCTAssertEqual(sut.getAll(), [old])

        let new = WCSession.stub(topic: old.topic, timestamp: Date())

        XCTAssertTrue(sut.setSessionIfNewer(new))
        XCTAssertEqual(sut.getAll(), [new])
    }

    func testSetMultipleSessions() {
        let one = WCSession.stub()
        let two = WCSession.stub()

        XCTAssertTrue(sut.setSessionIfNewer(one))
        XCTAssertTrue(sut.setSessionIfNewer(two))
        XCTAssertEqual(sut.getAll().count, 2)
    }
}
