import XCTest
import JSONRPC
@testable import WalletConnectSign

final class RPCIDTests: XCTestCase {

    func testTimestamp() {
        let request = RPCRequest(method: "method")
        let response = RPCResponse(matchingRequest: request, error: JSONRPCError(code: 0, message: "message"))
        let timestamp = Date(timeIntervalSince1970: TimeInterval(request.id!.right! / 1000 / 1000))
        
        XCTAssertEqual(response.id!.right!.description.count, 16)
        XCTAssertEqual(response.id!.timestamp, timestamp)
        XCTAssertTrue(Calendar.current.isDateInToday(response.id!.timestamp))
    }
}
