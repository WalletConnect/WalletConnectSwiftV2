import XCTest
import Commons
import TestingUtils
@testable import JSONRPC

private func makeResultResponses() -> [RPCResponse] {
    return [
        RPCResponse(id: Int64.random(), result: Int.random()),
        RPCResponse(id: Int64.random(), result: Bool.random()),
        RPCResponse(id: Int64.random(), result: String.random()),
        RPCResponse(id: Int64.random(), result: (1...10).map { String($0) }),
        RPCResponse(id: Int64.random(), result: EmptyCodable()),
        RPCResponse(id: String.random(), result: Int.random()),
        RPCResponse(id: RPCID(String.random()), outcome: .response(AnyCodable(Int.random())))
    ]
}

private func makeErrorResponses() -> [RPCResponse] {
    return [
        RPCResponse(id: Int64.random(), error: JSONRPCError.stub()),
        RPCResponse(id: String.random(), error: JSONRPCError.stub(data: AnyCodable(Int.random()))),
        RPCResponse(id: Int64.random(), errorCode: Int.random(), message: String.random(), associatedData: AnyCodable(String.random())),
        RPCResponse(id: String.random(), errorCode: Int.random(), message: String.random(), associatedData: nil),
        RPCResponse(id: RPCID(String.random()), outcome: .error(JSONRPCError.stub()))
    ]
}

final class RPCResponseTests: XCTestCase {

    // MARK: - Init & Codable Tests

    func testInitWithResult() {
        let responses = makeResultResponses()
        responses.forEach { response in
            XCTAssertEqual(response.jsonrpc, "2.0")
            XCTAssertNotNil(response.id)
            XCTAssertNotNil(response.result)
            XCTAssertNil(response.error)
        }
    }

    func testInitWithError() {
        let responses = makeErrorResponses()
        responses.forEach { response in
            XCTAssertEqual(response.jsonrpc, "2.0")
            XCTAssertNotNil(response.id)
            XCTAssertNil(response.result)
            XCTAssertNotNil(response.error)
        }
    }

    func testRoundTripResultCoding() throws {
        let responses = makeResultResponses()
        try responses.forEach { response in
            let encoded = try JSONEncoder().encode(response)
            let decoded = try JSONDecoder().decode(RPCResponse.self, from: encoded)
            XCTAssertEqual(decoded, response)
        }
    }

    func testRoundTripErrorCoding() throws {
        let responses = makeErrorResponses()
        try responses.forEach { response in
            let encoded = try JSONEncoder().encode(response)
            let decoded = try JSONDecoder().decode(RPCResponse.self, from: encoded)
            XCTAssertEqual(decoded, response)
        }
    }

    func testNullIdentifierError() throws {
        let response = RPCResponse(errorWithoutID: JSONRPCError.stub())
        XCTAssertEqual(response.jsonrpc, "2.0")
        XCTAssertNil(response.id)
        XCTAssertNil(response.result)
        XCTAssertNotNil(response.error)
        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(RPCResponse.self, from: encoded)
        XCTAssertEqual(decoded, response)
    }

    // MARK: - Decode Result Tests

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

    // MARK: - Decode Error Tests

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

    // MARK: - Invalid Data Tests

    func testInvalidResponseDecode() {
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.ambiguousResult), "A response must not include both result and error members.")
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.absentResult), "A response must include either a result or an error member.")
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.badVersion), "JSON-RPC version must be exactly '2.0'.")
        XCTAssertThrowsError(try JSONDecoder().decode(RPCResponse.self, from: InvalidResponseJSON.successWithoutIdentifier), "A success response must have an 'id' member.")
    }
}
