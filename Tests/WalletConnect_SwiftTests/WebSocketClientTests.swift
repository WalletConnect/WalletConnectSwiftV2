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
    
    func testSendMessage() {
        let expectedMessage = "message"
        sut.connect(on: URL.stub())
        sut.send(expectedMessage)
        XCTAssertTrue(webSocketTaskMock.didCallSend)
        guard case .string(let message) = webSocketTaskMock.lastMessageSent else { XCTFail(); return }
        XCTAssertEqual(message, expectedMessage)
    }
}

final class URLSessionMock: URLSessionProtocol {
    
    let webSocketTaskMock: URLSessionWebSocketTaskMock
    
    var lastSessionTaskURL: URL?
    
    init(webSocketTaskMock: URLSessionWebSocketTaskMock) {
        self.webSocketTaskMock = webSocketTaskMock
    }
    
    func webSocketTask(with url: URL) -> URLSessionWebSocketTaskProtocol {
        lastSessionTaskURL = url
        return webSocketTaskMock
    }
}

final class URLSessionWebSocketTaskMock: URLSessionWebSocketTaskProtocol {
    
    var didCallResume = false
    var didCallCancel = false
    
    var lastMessageSent: URLSessionWebSocketTask.Message?
    var didCallSend: Bool {
        lastMessageSent != nil
    }
    
    var didCallReceive = false
    
    func resume() {
        didCallResume = true
    }
    
    func cancel() {
        didCallCancel = true
    }
    
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void) {
        lastMessageSent = message
    }
    
    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        didCallReceive = true
    }
}

extension URL {
    
    static func stub() -> URL {
        URL(string: "https://httpbin.org")!
    }
}
