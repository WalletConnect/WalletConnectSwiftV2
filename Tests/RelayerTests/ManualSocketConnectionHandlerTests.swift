import Foundation
import XCTest
@testable import WalletConnectRelay

final class ManualSocketConnectionHandlerTests: XCTestCase {
    var sut: ManualSocketConnectionHandler!
    var socket: WebSocketConnecting!
    var networkMonitor: NetworkMonitoringMock!
    override func setUp() {
        socket = WebSocketMock()

        let defaults = RuntimeKeyValueStorage()
        let logger = ConsoleLoggerMock()
        let networkMonitor = NetworkMonitoringMock()
        let keychainStorageMock = DispatcherKeychainStorageMock()
        let clientIdStorage = ClientIdStorage(defaults: defaults, keychain: keychainStorageMock, logger: logger)


        let socketAuthenticator = ClientIdAuthenticator(clientIdStorage: clientIdStorage)
        let relayUrlFactory = RelayUrlFactory(
            relayHost: "relay.walletconnect.com",
            projectId: "1012db890cf3cfb0c1cdc929add657ba",
            socketAuthenticator: socketAuthenticator
        )

        sut = ManualSocketConnectionHandler(socket: socket, logger: ConsoleLoggerMock())
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
