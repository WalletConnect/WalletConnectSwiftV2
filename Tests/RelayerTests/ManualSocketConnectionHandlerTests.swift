import Foundation
import XCTest
@testable import WalletConnectRelay

final class ManualSocketConnectionHandlerTests: XCTestCase {
    var sut: ManualSocketConnectionHandler!
    var socket: WebSocketConnecting!
    var networkMonitor: NetworkMonitoringMock!
    override func setUp() {
        socket = WebSocketMock()
        sut = ManualSocketConnectionHandler(socket: socket)
    }

    func testHandleDisconnect() {
        socket.connect()
        XCTAssertTrue(socket.isConnected)
        try! sut.handleDisconnect(closeCode: .normalClosure)
        XCTAssertFalse(socket.isConnected)
    }

    func testHandleConnect() {
        XCTAssertFalse(socket.isConnected)
        try! sut.handleConnect()
        XCTAssertTrue(socket.isConnected)
    }
}
