import XCTest
@testable import JSONRPC

final class RPCResponseTests: XCTestCase {

    func testRoundTripCoding() throws {
        let response = RPCResponse(id: 0, result: true)
        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(RPCResponse.self, from: encoded)
        XCTAssertEqual(decoded, response)
    }
    
    func testDecodeResultInt() throws {
        let intResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.intResult)
        let intValue = try intResponse.result?.get(Int.self)
        XCTAssertEqual(intValue, 69)
        XCTAssertNotNil(intResponse.id)
        XCTAssertNil(intResponse.error)
    }
    
    func testDecodeResultDouble() throws {
        let doubleResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.doubleResult)
        let doubleValue = try doubleResponse.result?.get(Double.self) ?? 0.0
        XCTAssertEqual(doubleValue, .pi, accuracy: 0.00000001)
        XCTAssertNotNil(doubleResponse.id)
        XCTAssertNil(doubleResponse.error)
    }
    
    func testDecodeResultString() throws {
        let stringResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.stringResult)
        let stringValue = try stringResponse.result?.get(String.self)
        XCTAssertEqual(stringValue, "0xdeadbeef")
        XCTAssertNotNil(stringResponse.id)
        XCTAssertNil(stringResponse.error)
    }
    
    func testDecodeResultBool() throws {
        let boolResponse = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.boolResult)
        let boolValue = try boolResponse.result?.get(Bool.self)
        XCTAssertEqual(boolValue, true)
        XCTAssertNotNil(boolResponse.id)
        XCTAssertNil(boolResponse.error)
    }
    
    // TODO: response with structured values tests
    
    func testDecodeResponseIdentifier() throws {
        let numberResponseId = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.intResult).id
        XCTAssert(numberResponseId?.isNumber == true)

        let stringResponseId = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.withStringIdentifier).id
        XCTAssert(stringResponseId?.isString == true)

        let explicitNullResponseId = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.errorWithExplicitNullIdentifier).id
        XCTAssertNil(explicitNullResponseId)

        let implicitNullResponseId = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.errorWithImplicitNullIdentifier).id
        XCTAssertNil(implicitNullResponseId)
    }
}
