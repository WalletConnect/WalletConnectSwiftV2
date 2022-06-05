import XCTest
//import Commons
//import TestingUtils
@testable import JSONRPC

final class RPCRequestTests: XCTestCase {
    
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
