import XCTest
@testable import JSONRPC

enum ResponseJSON {
    
    static let intResult = """
{
    "jsonrpc": "2.0",
    "result": 69,
    "id": 1
}
""".data(using: .utf8)!
    
    static let doubleResult = """
{
    "jsonrpc": "2.0",
    "result": 3.14159265,
    "id": 1
}
""".data(using: .utf8)!
    
    static let stringResult = """
{
    "id": 1,
    "jsonrpc": "2.0",
    "result": "0xdeadbeef"
}
""".data(using: .utf8)!
    
    static let boolResult = """
{
    "jsonrpc": "2.0",
    "result": true,
    "id": 1
}
""".data(using: .utf8)!
}

final class JSONRPCTests: XCTestCase {

    // Response Tests
    func testRoundTripCoding() throws {
        let response = RPCResponse(id: 0, result: true)
        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(RPCResponse.self, from: encoded)
        XCTAssertEqual(decoded, response)
    }
    
    func testResponseDecodeInt() throws {
        let intResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.intResult)
        let intValue = try intResponse.result?.get(Int.self)
        XCTAssertEqual(intValue, 69)
        XCTAssertNotNil(intResponse.id)
        XCTAssertNil(intResponse.error)
    }
    
    func testResponseDecodeDouble() throws {
        let doubleResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.doubleResult)
        let doubleValue = try doubleResponse.result?.get(Double.self) ?? 0.0
        XCTAssertEqual(doubleValue, .pi, accuracy: 0.00000001)
        XCTAssertNotNil(doubleResponse.id)
        XCTAssertNil(doubleResponse.error)
    }
    
    func testResponseDecodeString() throws {
        let stringResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.stringResult)
        let stringValue = try stringResponse.result?.get(String.self)
        XCTAssertEqual(stringValue, "0xdeadbeef")
        XCTAssertNotNil(stringResponse.id)
        XCTAssertNil(stringResponse.error)
    }
    
    func testResponseDecodeBool() throws {
        let boolResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.boolResult)
        let boolValue = try boolResponse.result?.get(Bool.self)
        XCTAssertEqual(boolValue, true)
        XCTAssertNotNil(boolResponse.id)
        XCTAssertNil(boolResponse.error)
    }
    
    // TODO: response with structured values tests
}
