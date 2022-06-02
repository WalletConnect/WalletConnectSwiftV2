import XCTest
@testable import JSONRPC

final class JSONRPCTests: XCTestCase {

    func testRoundTripCoding() throws {
        let response = RPCResponse(id: 0, result: true)
        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(RPCResponse.self, from: encoded)
        XCTAssertEqual(decoded, response)
    }
}
