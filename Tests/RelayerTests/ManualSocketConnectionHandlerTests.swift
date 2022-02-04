

import Foundation
import XCTest
@testable import Relayer

final class ManualSocketConnectionHandlerTests: XCTestCase {
    var sut: Dispatcher!
    var webSocketSession: WebSocketSessionMock!
    var networkMonitor: NetworkMonitoringMock!
    var socketConnectionObserver: SocketConnectionObserverMock!
    override func setUp() {
        webSocketSession = WebSocketSessionMock()
        networkMonitor = NetworkMonitoringMock()
        socketConnectionObserver = SocketConnectionObserverMock()
        sut = Dispatcher(networkMonitor: networkMonitor, socket: webSocketSession, socketConnectionObserver: socketConnectionObserver, socketConnectionHandler: ManualSocketConnectionHandler(socket: webSocketSession))
    }
    
//    func testDisconnectOnConnectionLoss() {
//        try! sut.connect()
//        XCTAssertTrue(sut.socket.isConnected)
//        networkMonitor.onUnsatisfied?()
//        XCTAssertFalse(sut.socket.isConnected)
//    }
//
//    func testConnectsOnConnectionSatisfied() {
//        try! sut.disconnect(closeCode: .normalClosure)
//        XCTAssertFalse(sut.socket.isConnected)
//        networkMonitor.onSatisfied?()
//        XCTAssertTrue(sut.socket.isConnected)
//    }
//
}
