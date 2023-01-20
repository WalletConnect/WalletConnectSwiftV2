import XCTest
@testable import WalletConnectSign

final class SessionRequestTests: XCTestCase {

    func testRequestTtlDefault() {
        let request = Request.stub()

        XCTAssertEqual(request.calculateTtl(), SessionRequestProtocolMethod.defaultTtl)
    }

    func testRequestTtlExtended() {
        let currentDate = Date(timeIntervalSince1970: 0)
        let expiry = currentDate.advanced(by: 500)
        let request = Request.stub(expiry: UInt64(expiry.timeIntervalSince1970))

        XCTAssertEqual(request.calculateTtl(currentDate: currentDate), 500)
    }

    func testRequestTtlNotExtendedMinValidation() {
        let currentDate = Date(timeIntervalSince1970: 0)
        let expiry = currentDate.advanced(by: 200)
        let request = Request.stub(expiry: UInt64(expiry.timeIntervalSince1970))

        XCTAssertEqual(request.calculateTtl(currentDate: currentDate), SessionRequestProtocolMethod.defaultTtl)
    }

    func testRequestTtlNotExtendedMaxValidation() {
        let currentDate = Date(timeIntervalSince1970: 0)
        let expiry = currentDate.advanced(by: 700000)
        let request = Request.stub(expiry: UInt64(expiry.timeIntervalSince1970))

        XCTAssertEqual(request.calculateTtl(currentDate: currentDate), SessionRequestProtocolMethod.defaultTtl)
    }

    func testIsExpiredDefault() {
        let request = Request.stub()

        XCTAssertFalse(request.isExpired())
    }

    func testIsExpiredTrue() {
        let currentDate = Date(timeIntervalSince1970: 500)
        let expiry = Date(timeIntervalSince1970: 0)
        let request = Request.stub(expiry: UInt64(expiry.timeIntervalSince1970))
        XCTAssertTrue(request.isExpired(currentDate: currentDate))
    }

    func testIsExpiredTrueMinValidation() {
        let currentDate = Date(timeIntervalSince1970: 500)
        let expiry = Date(timeIntervalSince1970: 600)
        let request = Request.stub(expiry: UInt64(expiry.timeIntervalSince1970))
        XCTAssertTrue(request.isExpired(currentDate: currentDate))
    }

    func testIsExpiredTrueMaxValidation() {
        let currentDate = Date(timeIntervalSince1970: 500)
        let expiry = Date(timeIntervalSince1970: 700000)
        let request = Request.stub(expiry: UInt64(expiry.timeIntervalSince1970))
        XCTAssertTrue(request.isExpired(currentDate: currentDate))
    }

    func testIsExpiredFalse() {
        let currentDate = Date(timeIntervalSince1970: 0)
        let expiry = Date(timeIntervalSince1970: 500)
        let request = Request.stub(expiry: UInt64(expiry.timeIntervalSince1970))

        XCTAssertFalse(request.isExpired(currentDate: currentDate))
    }
}

private extension Request {

    static func stub(expiry: UInt64? = nil) -> Request {
        return Request(
            topic: "topic",
            method: "method",
            params: AnyCodable("params"),
            chainId: Blockchain("eip155:1")!,
            expiry: expiry
        )
    }
}
