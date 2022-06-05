import XCTest
//import Commons
//import TestingUtils
@testable import JSONRPC

enum RequestJSON {
    
    static let paramsByPosition = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": [
        69,
        "aaa"
    ],
    "id": 1
}
""".data(using: .utf8)!
    
    static let paramsByName = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": {
        "number": 69,
        "string": "aaa",
        "bool": true
    },
    "id": 1
}
""".data(using: .utf8)!
    
    static let paramsOmitted = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "id": 1
}
""".data(using: .utf8)!
    
    // string ID
    
    // nil ID / notification
}

enum InvalidRequestJSON {
    
    static let badVersion = """
{
    "jsonrpc": "1.0",
    "method": "request",
    "params": {
        "number": 69
    },
    "id": 1
}
""".data(using: .utf8)!
    
    // empty method?
    
    static let intPrimitiveParams = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": 420,
    "id": 1
}
""".data(using: .utf8)!
    
    static let stringPrimitiveParams = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": "0xdeadbeef",
    "id": 1
}
""".data(using: .utf8)!
    
    static let boolPrimitiveParams = """
{
    "jsonrpc": "2.0",
    "method": "request",
    "params": true,
    "id": 1
}
""".data(using: .utf8)!
}

final class RPCRequestTests: XCTestCase {
    
    func testDecodeParamsByPosition() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.paramsByPosition)
        XCTAssertNotNil(request.params)
    }
    
    func testDecodeParamsByName() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.paramsByName)
        XCTAssertNotNil(request.params)
    }
    
    func testDecodeOmittedParams() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.paramsOmitted)
        XCTAssertNil(request.params)
    }
    
    func testInvalidRequestDecode() {
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.badVersion))
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.intPrimitiveParams))
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.stringPrimitiveParams))
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.boolPrimitiveParams))
    }
}
