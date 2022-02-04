
import Foundation
import XCTest
@testable import Relayer

class AppStateObserverMock: AppStateObserving {
    var onWillEnterForeground: (() -> ())?
    var onWillEnterBackground: (() -> ())?
}

final class AutomaticSocketConnectionHandlerTests: XCTestCase {
    var sut: AutomaticSocketConnectionHandler!
    var webSocketSession: WebSocketSessionMock!
    var networkMonitor: NetworkMonitoringMock!
    var socketConnectionObserver: SocketConnectionObserverMock!
    var appStateObserver: AppStateObserving!
    override func setUp() {
        webSocketSession = WebSocketSessionMock()
        networkMonitor = NetworkMonitoringMock()
        appStateObserver = AppStateObserverMock()
        socketConnectionObserver = SocketConnectionObserverMock()
        sut = AutomaticSocketConnectionHandler(networkMonitor: networkMonitor, socket: webSocketSession, appStateObserver: appStateObserver)
    }
    
    func testDisconnectOnConnectionLoss() {
        webSocketSession.connect()
        XCTAssertTrue(sut.socket.isConnected)
        networkMonitor.onUnsatisfied?()
        XCTAssertFalse(sut.socket.isConnected)
    }

    func testConnectsOnConnectionSatisfied() {
        webSocketSession.disconnect(with: .normalClosure)
        XCTAssertFalse(sut.socket.isConnected)
        networkMonitor.onSatisfied?()
        XCTAssertTrue(sut.socket.isConnected)
    }
    
    func testHandleConnectThrows() {
        XCTAssertThrowsError(try sut.handleConnect())
    }

    func testHandleDisconnectThrows() {
        XCTAssertThrowsError(try sut.handleDisconnect(closeCode: .normalClosure))
    }
    
    func testReconnectsOnEnterForeground() {
        webSocketSession.disconnect(with: .normalClosure)
        appStateObserver.onWillEnterForeground?()
        XCTAssertTrue(sut.socket.isConnected)
    }
    
    func testRegisterTaskOnEnterBackground() {
        
    }
    
    func testDisconnectOnEndBackgroundTask() {
        
    }
}
