import Foundation
import XCTest
@testable import WalletConnectRelay
import TestingUtils
import Combine

class WebSocketMock: WebSocketConnecting {
    var request: URLRequest = URLRequest(url: URL(string: "wss://relay.walletconnect.com")!)

    var onText: ((String) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var sendCallCount: Int = 0
    var isConnected: Bool = false

    func connect() {
        isConnected = true
        onConnect?()
    }

    func disconnect() {
        isConnected = false
        onDisconnect?(nil)
    }

    func write(string: String, completion: (() -> Void)?) {
        sendCallCount+=1
    }
}

final class DispatcherTests: XCTestCase {
    var sut: Dispatcher!
    var webSocket: WebSocketMock!
    var networkMonitor: NetworkMonitoringMock!
    override func setUp() {
        webSocket = WebSocketMock()
        networkMonitor = NetworkMonitoringMock()
        sut = Dispatcher(socket: webSocket, socketConnectionHandler: ManualSocketConnectionHandler(socket: webSocket), logger: ConsoleLoggerMock())
    }

    func testSendWhileConnected() {
        try! sut.connect()
        sut.send("1") {_ in}
        XCTAssertEqual(webSocket.sendCallCount, 1)
    }

//    func testTextFramesSentAfterReconnectingSocket() {
//        try! sut.disconnect(closeCode: .normalClosure)
//        sut.send("1"){_ in}
//        sut.send("2"){_ in}
//        XCTAssertEqual(webSocketSession.sendCallCount, 0)
//        try! sut.connect()
//        socketConnectionObserver.onConnect?()
//        XCTAssertEqual(webSocketSession.sendCallCount, 2)
//    }

    func testOnMessage() {
        let expectation = expectation(description: "on message")
        sut.onMessage = { message in
            XCTAssertNotNil(message)
            expectation.fulfill()
        }
        webSocket.onText?("message")
        waitForExpectations(timeout: 0.001)
    }

    func testOnConnect() {
        let expectation = expectation(description: "on connect")
        sut.onConnect = {
            expectation.fulfill()
        }
        webSocket.onConnect?()
        waitForExpectations(timeout: 0.001)
    }

    func testOnDisconnect() {
        let expectation = expectation(description: "on disconnect")
        sut.onDisconnect = {
            expectation.fulfill()
        }
        webSocket.onDisconnect?(nil)
        waitForExpectations(timeout: 0.001)
    }
}
