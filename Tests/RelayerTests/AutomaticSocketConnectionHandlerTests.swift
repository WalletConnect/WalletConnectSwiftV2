import Foundation
import XCTest
@testable import WalletConnectRelay

final class AutomaticSocketConnectionHandlerTests: XCTestCase {
    var sut: AutomaticSocketConnectionHandler!
    var webSocketSession: WebSocketMock!
    var networkMonitor: NetworkMonitoringMock!
    var appStateObserver: AppStateObserverMock!
    var backgroundTaskRegistrar: BackgroundTaskRegistrarMock!

    override func setUp() {
        webSocketSession = WebSocketMock()
        networkMonitor = NetworkMonitoringMock()
        appStateObserver = AppStateObserverMock()
        backgroundTaskRegistrar = BackgroundTaskRegistrarMock()
        sut = AutomaticSocketConnectionHandler(
            socket: webSocketSession,
            networkMonitor: networkMonitor,
            appStateObserver: appStateObserver,
        backgroundTaskRegistrar: backgroundTaskRegistrar)
    }

    func testConnectsOnConnectionSatisfied() {
        webSocketSession.disconnect()
        XCTAssertFalse(webSocketSession.isConnected)
        networkMonitor.onSatisfied?()
        XCTAssertTrue(webSocketSession.isConnected)
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
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testRegisterTaskOnEnterBackground() {
        XCTAssertNil(backgroundTaskRegistrar.completion)
        appStateObserver.onWillEnterBackground?()
        XCTAssertNotNil(backgroundTaskRegistrar.completion)
    }

    func testDisconnectOnEndBackgroundTask() {
        appStateObserver.onWillEnterBackground?()
        XCTAssertTrue(webSocketSession.isConnected)
        backgroundTaskRegistrar.completion!()
        XCTAssertFalse(webSocketSession.isConnected)
    }

    func testReconnectOnDisconnectForeground() async {
        appStateObserver.currentState = .foreground
        XCTAssertTrue(webSocketSession.isConnected)
        webSocketSession.disconnect()
        await sut.handleDisconnection()
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testReconnectOnDisconnectBackground() async {
        appStateObserver.currentState = .background
        XCTAssertTrue(webSocketSession.isConnected)
        webSocketSession.disconnect()
        await sut.handleDisconnection()
        XCTAssertFalse(webSocketSession.isConnected)
    }
}
