import XCTest
@testable import WalletConnectSign

final class WCResponseTests: XCTestCase {

    func testTimestamp() {
        let request = WCRequest(
            method: .pairingPing,
            params: .pairingPing(.init())
        )
        let response = WCResponse.stubError(forRequest: request, topic: "topic")
        let timestamp = Date(timeIntervalSince1970: TimeInterval(request.id / 1000 / 1000))

        XCTAssertEqual(response.timestamp, timestamp)
        XCTAssertTrue(Calendar.current.isDateInToday(response.timestamp))
    }
}
