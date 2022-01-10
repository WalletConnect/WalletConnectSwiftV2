
import Foundation
import XCTest
@testable import Relayer

final class DispatcherTests: XCTestCase {
    var sut: Dispatcher!
    var webSocketSession: WebSocketSessionMock!
    var networkMonitor: NetworkMonitoringMock!
    var socketConnectionObserver: SocketConnectionObserverMock!
    override func setUp() {
        webSocketSession = WebSocketSessionMock()
        networkMonitor = NetworkMonitoringMock()
        socketConnectionObserver = SocketConnectionObserverMock()
        let url = URL(string: "ws://staging.walletconnect.org")!
        sut = Dispatcher(url: url, networkMonitor: networkMonitor, socket: webSocketSession, socketConnectionObserver: socketConnectionObserver)
    }
    
    func testDisconnectOnConnectionLoss() {
        XCTAssertTrue(sut.socket.isConnected)
        networkMonitor.onUnsatisfied?()
        XCTAssertFalse(sut.socket.isConnected)
    }
    
    func testConnectsOnConnectionSatisfied() {
        sut.disconnect(closeCode: .normalClosure)
        XCTAssertFalse(sut.socket.isConnected)
        networkMonitor.onSatisfied?()
        XCTAssertTrue(sut.socket.isConnected)
    }
    
    func testSendWhileConnected() {
        sut.connect()
        sut.send("1"){_ in}
        XCTAssertEqual(webSocketSession.sendCallCount, 1)
    }
        
    func testTextFramesSentAfterReconnectingSocket() {
        sut.disconnect(closeCode: .normalClosure)
        sut.send("1"){_ in}
        sut.send("2"){_ in}
        XCTAssertEqual(webSocketSession.sendCallCount, 0)
        sut.connect()
        socketConnectionObserver.onConnect?()
        XCTAssertEqual(webSocketSession.sendCallCount, 2)
    }
    
    func testOnMessage() {
        let expectation = expectation(description: "on message")
        sut.onMessage = { message in
            XCTAssertNotNil(message)
            expectation.fulfill()
        }
        webSocketSession.onMessageReceived?("message")
        waitForExpectations(timeout: 0.001)
    }
    
    func testOnConnect() {
        let expectation = expectation(description: "on connect")
        sut.onConnect = {
            expectation.fulfill()
        }
        socketConnectionObserver.onConnect?()
        waitForExpectations(timeout: 0.001)
    }
    
    func testOnDisconnect() {
        let expectation = expectation(description: "on disconnect")
        sut.onDisconnect = {
            expectation.fulfill()
        }
        socketConnectionObserver.onDisconnect?()
        waitForExpectations(timeout: 0.001)
    }
}


class SocketConnectionObserverMock: SocketConnectionObserving {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
}
