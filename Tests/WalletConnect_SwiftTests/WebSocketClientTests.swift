import XCTest
@testable import WalletConnect_Swift

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
    
    func testSendMessageFailsIfNotConnected() {
        sut.send("")
        XCTAssertFalse(webSocketTaskMock.didCallSend)
    }
    
    func testSendMessageSuccess() {
        let expectedMessage = "message"
        var didCallbackError = false
        sut.onError = { _ in didCallbackError = true }
        
        sut.connect(on: URL.stub())
        sut.send(expectedMessage)
        
        XCTAssertTrue(webSocketTaskMock.didCallSend)
        XCTAssertFalse(didCallbackError)
        guard case .string(let message) = webSocketTaskMock.lastMessageSent else { XCTFail(); return }
        XCTAssertEqual(message, expectedMessage)
    }

    func testSendMessageFailure() {
        var didCallbackError = false
        sut.onError = { _ in didCallbackError = true }
        webSocketTaskMock.sendMessageError = NSError(domain: "", code: -9999, userInfo: nil)
        
        sut.connect(on: URL.stub())
        sut.send("")
        
        XCTAssertTrue(didCallbackError)
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
        sut.onError = { _ in didCallbackError = true }
        webSocketTaskMock.receiveMessageResult = .success(.data("message".data(using: .utf8)!))
        
        sut.connect(on: URL.stub())
        
        XCTAssertNil(callbackMessage)
        XCTAssertFalse(didCallbackError)
        XCTAssert(webSocketTaskMock.receiveCallsCount == 2)
    }
    
    func testReceiveMessageFailure() {
        var didCallbackError = false
        sut.onError = { _ in didCallbackError = true }
        webSocketTaskMock.receiveMessageResult = .failure(NSError(domain: "", code: -9999, userInfo: nil))
        
        sut.connect(on: URL.stub())
        
        XCTAssertTrue(didCallbackError)
        XCTAssert(webSocketTaskMock.receiveCallsCount == 2)
    }
}
