
import Foundation

import XCTest
import CryptoKit
@testable import WalletConnect

final class JsonRpcHistoryTests: XCTestCase {
    
    var sut: JsonRpcHistory!
    
    var fakeKeychain: KeychainServiceFake!
    
    let defaultIdentifier = "key"
    
    override func setUp() {
        sut = JsonRpcHistory(logger: MuteLogger(), storage: RuntimeKeyValueStorage())
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testSetRecord() {
        let recordinput = testJsonRpcRecordInput
        XCTAssertFalse(sut.exist(id: recordinput.request.id))
        try! sut.set(topic: recordinput.topic, request: recordinput.request, chainId: recordinput.chainId)
        XCTAssertTrue(sut.exist(id: recordinput.request.id))
    }
    
    func testGetRecord() {
        let recordinput = testJsonRpcRecordInput
        XCTAssertNil(sut.get(id: recordinput.request.id))
        try! sut.set(topic: recordinput.topic, request: recordinput.request, chainId: recordinput.chainId)
        XCTAssertNotNil(sut.get(id: recordinput.request.id))
    }
    
    func testResolve() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request, chainId: recordinput.chainId)
        XCTAssertNil(sut.get(id: recordinput.request.id)?.response)
        let jsonRpcResponse = JSONRPCResponse<AnyCodable>(id: recordinput.request.id, result: AnyCodable(""))
        let response = JsonRpcRecord.Response.response(jsonRpcResponse)
        try! sut.resolve(response: response)
        XCTAssertNotNil(sut.get(id: jsonRpcResponse.id)?.response)
    }
    
    func testThrowsOnResolveDuplicate() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request, chainId: recordinput.chainId)
        let jsonRpcResponse = JSONRPCResponse<AnyCodable>(id: recordinput.request.id, result: AnyCodable(""))
        let response = JsonRpcRecord.Response.response(jsonRpcResponse)
        try! sut.resolve(response: response)
        XCTAssertThrowsError(try sut.resolve(response: response))
    }
    
    func testThrowsOnSetDuplicate() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request, chainId: recordinput.chainId)
        XCTAssertThrowsError(try sut.set(topic: recordinput.topic, request: recordinput.request, chainId: recordinput.chainId))
    }
    
    func testDelete() {
        let recordinput = testJsonRpcRecordInput
        try! sut.set(topic: recordinput.topic, request: recordinput.request, chainId: recordinput.chainId)
        sut.delete(id: recordinput.request.id)
        XCTAssertNil(sut.get(id: recordinput.request.id))
    }
}

private var testJsonRpcRecordInput: (topic: String, request: JSONRPCRequest<AnyCodable>, chainId: String) {
    let params = SessionType.UpdateParams(state: SessionType.State(accounts: ["0xDMT"]))
    let request = JSONRPCRequest<AnyCodable>(method: "wc_sessionUpdate", params: AnyCodable(params))
    return (topic: "123", request: request, chainId: "eip155-1")
}
