
import Foundation
import XCTest
@testable import WalletConnectRelay

final class AutomaticSocketConnectionHandlerTests: XCTestCase {
    var sut: AutomaticSocketConnectionHandler!
    var webSocketSession: WebSocketConnecting!
    var networkMonitor: NetworkMonitoringMock!
    var appStateObserver: AppStateObserving!
    var backgroundTaskRegistrar: BackgroundTaskRegistrarMock!
    override func setUp() {
        webSocketSession = WebSocketMock()
        networkMonitor = NetworkMonitoringMock()
        appStateObserver = AppStateObserverMock()
        backgroundTaskRegistrar = BackgroundTaskRegistrarMock()
        sut = AutomaticSocketConnectionHandler(
            networkMonitor: networkMonitor,
            socket: webSocketSession,
            appStateObserver: appStateObserver,
        backgroundTaskRegistrar: backgroundTaskRegistrar)
    }

    func testConnectsOnConnectionSatisfied() {
        webSocketSession.disconnect()
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
        webSocketSession.disconnect()
        appStateObserver.onWillEnterForeground?()
        XCTAssertTrue(sut.socket.isConnected)
    }
    
    func testRegisterTaskOnEnterBackground() {
        XCTAssertNil(backgroundTaskRegistrar.completion)
        appStateObserver.onWillEnterBackground?()
        XCTAssertNotNil(backgroundTaskRegistrar.completion)
    }
    
    func testDisconnectOnEndBackgroundTask() {
        appStateObserver.onWillEnterBackground?()
        XCTAssertTrue(sut.socket.isConnected)
        backgroundTaskRegistrar.completion!()
        XCTAssertFalse(sut.socket.isConnected)
    }
}
