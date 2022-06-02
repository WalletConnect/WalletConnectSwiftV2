import XCTest
import Commons
@testable import JSONRPC

final class RPCResponseTests: XCTestCase {

    func testRoundTripCoding() throws {
        let responses = [
            RPCResponse(id: 0, result: 420),
            RPCResponse(id: "0", result: true),
            RPCResponse(id: 0, result: "string")
        ]
        try responses.forEach { response in
            let encoded = try JSONEncoder().encode(response)
            let decoded = try JSONDecoder().decode(RPCResponse.self, from: encoded)
            XCTAssertEqual(decoded, response)
        }
    }
    
    func testDecodeResultInt() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.intResult)
        let intValue = try response.result?.get(Int.self)
        XCTAssertEqual(intValue, 69)
        XCTAssertNotNil(response.id)
        XCTAssertNil(response.error)
    }
    
    func testDecodeResultDouble() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.doubleResult)
        let doubleValue = try response.result?.get(Double.self) ?? 0.0
        XCTAssertEqual(doubleValue, .pi, accuracy: 0.00000001)
        XCTAssertNotNil(response.id)
        XCTAssertNil(response.error)
    }
    
    func testDecodeResultString() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.stringResult)
        let stringValue = try response.result?.get(String.self)
        XCTAssertEqual(stringValue, "0xdeadbeef")
        XCTAssertNotNil(response.id)
        XCTAssertNil(response.error)
    }
    
    func testDecodeResultBool() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.boolResult)
        let boolValue = try response.result?.get(Bool.self)
        XCTAssertEqual(boolValue, true)
        XCTAssertNotNil(response.id)
        XCTAssertNil(response.error)
    }
    
    func testDecodeResultArray() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.arrayResult)
        let arrayValue = try response.result?.get([String].self)
        XCTAssertEqual(arrayValue?.count, 3)
        XCTAssertNotNil(response.id)
        XCTAssertNil(response.error)
    }
    
    func testDecodeResultObject() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.objectResult)
        let objectValue = try response.result?.get([String: AnyCodable].self)
        XCTAssertNotNil(response.id)
        XCTAssertNil(response.error)
        XCTAssertEqual(try? objectValue?["int"]?.get(Int.self), 0)
        XCTAssertEqual(try? objectValue?["bool"]?.get(Bool.self), false)
        XCTAssertEqual(try? objectValue?["string"]?.get(String.self), "0xc0ffee")
    }
    
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
    
    func testDecodeError() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.plainError)
        XCTAssertNil(response.result)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error?.code, -32600)
    }
    
    func testDecodeErrorWithPrimitiveData() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.errorWithPrimitiveData)
        XCTAssertNil(response.result)
        XCTAssertNotNil(response.error?.data)
        XCTAssertNotNil(try response.error?.data?.get(String.self))
    }

    func testDecodeErrorWithStructuredData() throws {
        let response = try JSONDecoder().decode(RPCResponse.self, from: ResponseJSON.errorWithStructuredData)
        XCTAssertNil(response.result)
        XCTAssertNotNil(response.error?.data)
        let heterogeneousArray = try response.error?.data?.get([AnyCodable].self)
        XCTAssertNotNil(try heterogeneousArray?[0].get(Int.self))
        XCTAssertNotNil(try heterogeneousArray?[1].get(Bool.self))
        XCTAssertNotNil(try heterogeneousArray?[2].get(String.self))
    }
    
    func testInvalidResponseDecode() {
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.ambiguousResult), "A response must not include both result and error members.")
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.absentResult), "A response must include either a result or an error member.")
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.badVersion), "JSON-RPC version must be exactly '2.0'.")
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.successWithoutIdentifier), "A success response must have an 'id' member.")
    }
}
