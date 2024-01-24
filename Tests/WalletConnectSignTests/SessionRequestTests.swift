import XCTest
@testable import WalletConnectSign

class RequestTests: XCTestCase {

    func testInitWithValidTtl() {
        XCTAssertNoThrow(try Request.stub(ttl: 3600)) // 1 hour
    }

    func testInitWithInvalidTtlTooShort() {
        XCTAssertThrowsError(try Request.stub(ttl: 100)) { error in // Less than minTtl
            XCTAssertEqual(error as? Request.Errors, Request.Errors.invalidTtl)
        }
    }

    func testInitWithInvalidTtlTooLong() {
        XCTAssertThrowsError(try Request.stub(ttl: 700000)) { error in // More than maxTtl
            XCTAssertEqual(error as? Request.Errors, Request.Errors.invalidTtl)
        }
    }

    func testIsExpiredForNonExpiredRequest() {
        let request = try! Request.stub(ttl: 3600) // 1 hour
        XCTAssertFalse(request.isExpired())
    }

    func testIsExpiredForExpiredRequest() {
        let pastTimestamp = UInt64(Date().timeIntervalSince1970) - 3600 // 1 hour ago
        let request = Request.stubWithExpiry(expiry: pastTimestamp)
        XCTAssertTrue(request.isExpired())
    }

    func testCalculateTtlForNonExpiredRequest() {
        let request = try! Request.stub(ttl: 3600) // 1 hour
        XCTAssertNoThrow(try request.calculateTtl())
    }

    func testCalculateTtlForExpiredRequest() {
        let pastTimestamp = UInt64(Date().timeIntervalSince1970) - 3600 // 1 hour ago
        let request = Request.stubWithExpiry(expiry: pastTimestamp)
        XCTAssertThrowsError(try request.calculateTtl()) { error in
            XCTAssertEqual(error as? Request.Errors, Request.Errors.requestExpired)
        }
    }
}



private extension Request {

    static func stub(ttl: TimeInterval = 300) throws -> Request {
        return try Request(
            topic: "topic",
            method: "method",
            params: AnyCodable("params"),
            chainId: Blockchain("eip155:1")!,
            ttl: ttl
        )
    }

    static func stubWithExpiry(expiry: UInt64) -> Request {
        return Request(
            id: RPCID(JsonRpcID.generate()),
            topic: "topic",
            method: "method",
            params: AnyCodable("params"),
            chainId: Blockchain("eip155:1")!,
            expiryTimestamp: expiry
        )
    }
}
