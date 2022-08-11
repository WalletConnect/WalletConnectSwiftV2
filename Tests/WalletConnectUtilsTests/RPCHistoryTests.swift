import XCTest
import JSONRPC
import TestingUtils
@testable import WalletConnectUtils

final class RPCHistoryTests: XCTestCase {

    var sut: RPCHistory!

    override func setUp() {
        let storage = CodableStore<RPCHistory.Record>(defaults: RuntimeKeyValueStorage(), identifier: "")
        sut = RPCHistory(keyValueStore: storage)
    }

    override func tearDown() {
        sut = nil
    }

    // MARK: History Storage Tests

    func testRoundTrip() throws {
        let request = RPCRequest.stub()
        try sut.set(request, forTopic: String.randomTopic(), emmitedBy: .local)
        let record = sut.get(recordId: request.id!)
        XCTAssertNil(record?.response)
        XCTAssertEqual(record?.request, request)
    }

    func testResolveSuccessAndError() throws {
        let requestA = RPCRequest.stub()
        let requestB = RPCRequest.stub()
        let responseA = RPCResponse(matchingRequest: requestA, result: true)
        let responseB = RPCResponse(matchingRequest: requestB, error: .internalError)
        try sut.set(requestA, forTopic: String.randomTopic(), emmitedBy: .remote)
        try sut.set(requestB, forTopic: String.randomTopic(), emmitedBy: .local)
        try sut.resolve(responseA)
        try sut.resolve(responseB)
        let recordA = sut.get(recordId: requestA.id!)
        let recordB = sut.get(recordId: requestB.id!)
        XCTAssertEqual(recordA?.response, responseA)
        XCTAssertEqual(recordB?.response, responseB)
    }

    func testDelete() throws {
        let requests = (1...5).map { _ in RPCRequest.stub() }
        let topic = String.randomTopic()
        try requests.forEach { try sut.set($0, forTopic: topic, emmitedBy: .local) }
        sut.deleteAll(forTopic: topic)
        requests.forEach {
            XCTAssertNil(sut.get(recordId: $0.id!))
        }
    }

    // MARK: Error Cases Tests

    func testSetUnidentifiedRequest() {
        let expectedError = RPCHistory.HistoryError.unidentifiedRequest

        let request = RPCRequest.notification(method: "notify")
        XCTAssertThrowsError(try sut.set(request, forTopic: String.randomTopic(), emmitedBy: .local)) { error in
            XCTAssertEqual(expectedError, error as? RPCHistory.HistoryError)
        }
    }

    func testSetDuplicateRequest() throws {
        let expectedError = RPCHistory.HistoryError.requestDuplicateNotAllowed

        let id = Int64.random()
        let requestA = RPCRequest.stub(method: "method-1", id: id)
        let requestB = RPCRequest.stub(method: "method-2", id: id)
        let topic = String.randomTopic()

        try sut.set(requestA, forTopic: topic, emmitedBy: .local)
        XCTAssertThrowsError(try sut.set(requestB, forTopic: topic, emmitedBy: .local)) { error in
            XCTAssertEqual(expectedError, error as? RPCHistory.HistoryError)
        }
    }

    func testResolveResponseWithoutRequest() throws {
        let expectedError = RPCHistory.HistoryError.requestMatchingResponseNotFound

        let response = RPCResponse(id: 0, result: true)
        XCTAssertThrowsError(try sut.resolve(response)) { error in
            XCTAssertEqual(expectedError, error as? RPCHistory.HistoryError)
        }
    }

    func testResolveUnidentifiedResponse() throws {
        let expectedError = RPCHistory.HistoryError.unidentifiedResponse

        let response = RPCResponse(errorWithoutID: JSONRPCError.internalError)
        XCTAssertThrowsError(try sut.resolve(response)) { error in
            XCTAssertEqual(expectedError, error as? RPCHistory.HistoryError)
        }
    }

    func testResolveDuplicateResponse() throws {
        let expectedError = RPCHistory.HistoryError.responseDuplicateNotAllowed

        let request = RPCRequest.stub()
        let responseA = RPCResponse(matchingRequest: request, result: true)
        let responseB = RPCResponse(matchingRequest: request, result: false)

        try sut.set(request, forTopic: String.randomTopic(), emmitedBy: .local)
        try sut.resolve(responseA)
        XCTAssertThrowsError(try sut.resolve(responseB)) { error in
            XCTAssertEqual(expectedError, error as? RPCHistory.HistoryError)
        }
    }
}
