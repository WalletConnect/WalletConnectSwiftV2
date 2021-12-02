
import Foundation

import XCTest
import CryptoKit
@testable import WalletConnect

final class JsonRpcHistoryTests: XCTestCase {
    
    var sut: JsonRpcHistory!
            
    override func setUp() {
        sut = JsonRpcHistory(logger: ConsoleLogger(), keyValueStorage: RuntimeKeyValueStorage())
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testSetRecord() {
        let recordinput = testJsonRpcRecordInput
        XCTAssertFalse(sut.exist(id: recordinput.request.id))
        try! sut.set(topic: recordinput.topic, request: recordinput.request)
        XCTAssertTrue(sut.exist(id: recordinput.request.id))
    }
    
    func testGetRecord() {
        let recordinput = testJsonRpcRecordInput
        XCTAssertNil(sut.get(id: recordinput.request.id))
        try! sut.set(topic: recordinput.topic, request: recordinput.request)
        XCTAssertNotNil(sut.get(id: recordinput.request.id))
    }
    
    func testResolve() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request)
        XCTAssertNil(sut.get(id: recordinput.request.id)?.response)
        let jsonRpcResponse = JSONRPCResponse<AnyCodable>(id: recordinput.request.id, result: AnyCodable(""))
        let response = JsonRpcResponseTypes.response(jsonRpcResponse)
        try! sut.resolve(response: response)
        XCTAssertNotNil(sut.get(id: jsonRpcResponse.id)?.response)
    }
    
    func testThrowsOnResolveDuplicate() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request)
        let jsonRpcResponse = JSONRPCResponse<AnyCodable>(id: recordinput.request.id, result: AnyCodable(""))
        let response = JsonRpcResponseTypes.response(jsonRpcResponse)
        try! sut.resolve(response: response)
        XCTAssertThrowsError(try sut.resolve(response: response))
    }
    
    func testThrowsOnSetDuplicate() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request)
        XCTAssertThrowsError(try sut.set(topic: recordinput.topic, request: recordinput.request))
    }
    
    func testDelete() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request)
        XCTAssertNotNil(sut.get(id: recordinput.request.id))
        sut.delete(topic: testTopic)
        XCTAssertNil(sut.get(id: recordinput.request.id))
    }
}

private let testTopic = "test_topic"
private var testJsonRpcRecordInput: (topic: String, request: WCRequest) {
    return (topic: testTopic, request: SerialiserTestData.pairingApproveJSONRPCRequest)
}
