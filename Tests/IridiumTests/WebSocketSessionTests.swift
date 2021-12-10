import XCTest
@testable import Iridium

final class WebSocketSessionTests: XCTestCase {
    
    var sut: WebSocketSession!
    
    var webSocketTaskMock: URLSessionWebSocketTaskMock!
    var sessionMock: URLSessionMock!
    
    override func setUp() {
        webSocketTaskMock = URLSessionWebSocketTaskMock()
        sessionMock = URLSessionMock(webSocketTaskMock: webSocketTaskMock)
        sut = WebSocketSession(session: sessionMock)
    }
    
    override func tearDown() {
        sut = nil
        sessionMock = nil
        webSocketTaskMock = nil
    }
    
    func testInitIsNotConnected() {
        XCTAssertFalse(sut.isConnected)
    }
    
    func testConnect() {
        let expectedURL = URL.stub()
        sut.connect(on: expectedURL)
        XCTAssertTrue(sut.isConnected)
        XCTAssertTrue(webSocketTaskMock.didCallResume)
        XCTAssertTrue(webSocketTaskMock.didCallReceive)
        XCTAssertEqual(sessionMock.lastSessionTaskURL, expectedURL)
    }
    
    func testDisconnect() {
        sut.connect(on: URL.stub())
        sut.disconnect()
        XCTAssertFalse(sut.isConnected)
        XCTAssertTrue(webSocketTaskMock.didCallCancel)
    }
    
    func testSendMessageSuccessCallbacksNoError() {
        let expectedMessage = "message"
        
        sut.connect(on: URL.stub())
        sut.send(expectedMessage) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertTrue(webSocketTaskMock.didCallSend)
        guard case .string(let message) = webSocketTaskMock.lastMessageSent else { XCTFail(); return }
        XCTAssertEqual(message, expectedMessage)
    }
    
    func testSendMessageFailsIfNotConnected() {
        sut.send("") { error in
            XCTAssertNotNil(error)
            XCTAssert(error?.asNetworkError?.isWebSocketError == true)
        }
        XCTAssertFalse(webSocketTaskMock.didCallSend)
    }

    func testSendMessageFailure() {
        webSocketTaskMock.sendMessageError = NSError.mock()
        
        sut.connect(on: URL.stub())
        sut.send("") { error in
            XCTAssertNotNil(error)
            XCTAssert(error?.asNetworkError?.isSendMessageError == true)
        }
        XCTAssertTrue(webSocketTaskMock.didCallSend)
    }
    
    func testReceiveMessageSuccess() {
        let expectedMessage = "message"
        var callbackMessage: String? = nil
        sut.onMessageReceived = { callbackMessage = $0 }
        webSocketTaskMock.receiveMessageResult = .success(.string(expectedMessage))
        
        sut.connect(on: URL.stub())
        
        XCTAssertEqual(callbackMessage, expectedMessage)
        XCTAssert(webSocketTaskMock.receiveCallsCount == 2)
    }
    
    func testReceiveMessageSuccessButUnexpectedType() {
        var callbackMessage: String? = nil
        sut.onMessageReceived = { callbackMessage = $0 }
        var didCallbackError = false
        sut.onMessageError = { _ in didCallbackError = true }
        webSocketTaskMock.receiveMessageResult = .success(.data("message".data(using: .utf8)!))
        
        sut.connect(on: URL.stub())
        
        XCTAssertNil(callbackMessage)
        XCTAssertFalse(didCallbackError)
        XCTAssert(webSocketTaskMock.receiveCallsCount == 2)
    }
    
    func testReceiveMessageFailure() {
        sut.onMessageError = { error in
            XCTAssertNotNil(error)
            XCTAssert(error.asNetworkError?.isReceiveMessageError == true)
        }
        webSocketTaskMock.receiveMessageResult = .failure(NSError.mock())
        
        sut.connect(on: URL.stub())
        
        XCTAssert(webSocketTaskMock.receiveCallsCount == 2)
    }
}
