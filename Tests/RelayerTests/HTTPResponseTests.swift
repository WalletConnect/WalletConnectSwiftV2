import XCTest
import TestingUtils
@testable import WalletConnectRelay

final class HTTPResponseTests: XCTestCase {

    static let url = URL(string: "https://httpbin.org/")!
    let request = URLRequest(url: url)
    let validData = try! JSONEncoder().encode("data")
    
    let successResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
    let failureResponse = HTTPURLResponse(url: url, statusCode: 400, httpVersion: "HTTP/1.1", headerFields: nil)

    // MARK: Success cases

    func testInitGetDecodableData() {
        let response: HTTPResponse<String> = HTTPResponse(request: request, data: validData, response: successResponse, error: nil)
        XCTAssertNoThrow(try response.result.get())
    }

    func testInitGetRawData() {
        let response: HTTPResponse<Data> = HTTPResponse(request: request, data: validData, response: successResponse, error: nil)
        XCTAssertNoThrow(try response.result.get())
    }

    // MARK: Failure cases

    func testInitWithError() {
        let response: HTTPResponse<String> = HTTPResponse(request: request, error: AnyError())
        XCTAssertNotNil(response.request)
        XCTAssertThrowsError(try response.result.get())
    }

    func testInitWithNoResponse() {
        let response: HTTPResponse<String> = HTTPResponse(request: request, data: validData, response: nil, error: nil)
        XCTAssertNil(response.urlResponse)
        XCTAssertThrowsError(try response.result.get()) { error in
            XCTAssert(error.asHttpError?.isNoResponseError == true)
        }
    }

    func testInitWithBadResponse() {
        let response: HTTPResponse<String> = HTTPResponse(request: request, data: validData, response: failureResponse, error: nil)
        XCTAssertThrowsError(try response.result.get()) { error in
            XCTAssert(error.asHttpError?.isBadStatusCodeError == true)
        }
    }

    func testInitWithNoData() {
        let response: HTTPResponse<String> = HTTPResponse(request: request, data: nil, response: successResponse, error: nil)
        XCTAssertThrowsError(try response.result.get()) { error in
            XCTAssert(error.asHttpError?.isNilDataError == true)
        }
    }

    func testInitWithInvalidData() {
        let response: HTTPResponse<Int> = HTTPResponse(request: request, data: validData, response: successResponse, error: nil)
        XCTAssertThrowsError(try response.result.get()) { error in
            XCTAssert(error.asHttpError?.isDecodeError == true)
        }
    }
}
