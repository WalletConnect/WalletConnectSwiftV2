import XCTest
import Commons
import TestingUtils
@testable import JSONRPC

private func makeRequests() -> [RPCRequest] {
    return [
        RPCRequest(method: String.random(), id: Int64.random()),
        RPCRequest(method: String.random(), id: String.random()),
        RPCRequest(method: String.random(), params: EmptyCodable(), id: Int64.random()),
        RPCRequest(method: String.random(), params: EmptyCodable(), id: String.random()),
        RPCRequest(method: String.random(), params: [0, 1, 2], id: Int64.random()),
        RPCRequest(method: String.random(), params: ["0", "1", "2"], id: String.random()),
        RPCRequest(method: String.random(), params: [AnyCodable(0), AnyCodable("0")], id: Int64.random()),
        RPCRequest(method: String.random(), params: [AnyCodable(0), AnyCodable("0")], id: String.random())
    ]
}

private func makeNotificationRequests() -> [RPCRequest] {
    return [
        RPCRequest.notification(method: String.random()),
        RPCRequest.notification(method: String.random(), params: EmptyCodable())
    ]
}

final class RPCRequestTests: XCTestCase {

    func testIdentifierGeneration() {
        let idGenerator = TestIdentifierGenerator()
        let cachedGenerator = RPCRequest.defaultIdentifierGenerator
        RPCRequest.defaultIdentifierGenerator = idGenerator
        let requestA = RPCRequest(method: String.random(), params: EmptyCodable())
        let requestB = RPCRequest(method: String.random())
        XCTAssertEqual(requestA.id, idGenerator.id)
        XCTAssertEqual(requestB.id, idGenerator.id)
        RPCRequest.defaultIdentifierGenerator = cachedGenerator
    }

    func testCheckedParamsInit() {
        XCTAssertNoThrow(try RPCRequest(method: "method", checkedParams: [0]))
        XCTAssertNoThrow(try RPCRequest(method: "method", checkedParams: [0], id: Int64.random()))
        XCTAssertNoThrow(try RPCRequest(method: "method", checkedParams: [0], id: String.random()))
        XCTAssertNoThrow(try RPCRequest(method: "method", checkedParams: EmptyCodable()))
        XCTAssertNoThrow(try RPCRequest(method: "method", checkedParams: EmptyCodable(), id: Int64.random()))
        XCTAssertNoThrow(try RPCRequest(method: "method", checkedParams: EmptyCodable(), id: String.random()))
    }

    func testCheckedParamsInitFailsWithPrimitives() {
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: 0, id: Int64.random()))
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: 0, id: String.random()))
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: "string", id: Int64.random()))
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: "string", id: String.random()))
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: Double.pi, id: Int64.random()))
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: Double.pi, id: String.random()))
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: true, id: Int64.random()))
        XCTAssertThrowsError(try RPCRequest(method: "method", checkedParams: true, id: String.random()))
    }

    func testRoundTripCoding() throws {
        let requests = makeRequests()
        try requests.forEach { request in
            let encoded = try JSONEncoder().encode(request)
            let decoded = try JSONDecoder().decode(RPCRequest.self, from: encoded)
            XCTAssertEqual(decoded, request)
            XCTAssertEqual(request.jsonrpc, "2.0")
            XCTAssertFalse(request.isNotification)
        }
    }

    func testNotificationRoundTrip() throws {
        let requests = makeNotificationRequests()
        try requests.forEach { request in
            let encoded = try JSONEncoder().encode(request)
            let decoded = try JSONDecoder().decode(RPCRequest.self, from: encoded)
            XCTAssertEqual(decoded, request)
            XCTAssertEqual(request.jsonrpc, "2.0")
            XCTAssertTrue(request.isNotification)
        }
    }

    func testDecodeParamsByPosition() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.paramsByPosition)
        XCTAssertNotNil(request.params)
        XCTAssertNotNil(request.id)
    }

    func testDecodeParamsByName() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.paramsByName)
        XCTAssertNotNil(request.params)
        XCTAssertNotNil(request.id)
    }

    func testDecodeParamsByPositionEmpty() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.emptyParamsByPosition)
        XCTAssertNotNil(request.params)
        XCTAssertNotNil(request.id)
    }

    func testDecodeParamsByNameEmpty() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.emptyParamsByName)
        XCTAssertNotNil(request.params)
        XCTAssertNotNil(request.id)
    }

    func testDecodeOmittedParams() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.paramsOmitted)
        XCTAssertNil(request.params)
        XCTAssertNotNil(request.id)
    }

    func testDecodeRequestIdentifier() throws {
        let numberRequestId = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.paramsByPosition).id
        XCTAssert(numberRequestId?.isNumber == true)
        let stringRequestId = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.withStringIdentifier).id
        XCTAssert(stringRequestId?.isString == true)
    }

    func testDecodeNotification() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.notification)
        XCTAssertNil(request.id)
        XCTAssertNotNil(request.params)

    }

    func testDecodeNotificationWithoutParams() throws {
        let request = try JSONDecoder().decode(RPCRequest.self, from: RequestJSON.notificationWithoutParams)
        XCTAssertNil(request.id)
        XCTAssertNil(request.params)
    }

    func testInvalidRequestDecode() {
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.badVersion))
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.intPrimitiveParams))
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.stringPrimitiveParams))
        XCTAssertThrowsError(try JSONDecoder().decode(RPCRequest.self, from: InvalidRequestJSON.boolPrimitiveParams))
    }
}
