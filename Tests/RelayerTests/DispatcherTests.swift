import Foundation
import XCTest
import Combine
@testable import WalletConnectRelay
import TestingUtils
import Combine

class DispatcherKeychainStorageMock: KeychainStorageProtocol {
    func add<T>(_ item: T, forKey key: String) throws where T : WalletConnectKMS.GenericPasswordConvertible {}
    func read<T>(key: String) throws -> T where T : WalletConnectKMS.GenericPasswordConvertible {
        return try T(rawRepresentation: Data())
    }
    func delete(key: String) throws {}
    func deleteAll() throws {}
}

final class DispatcherTests: XCTestCase {
    var publishers = Set<AnyCancellable>()
    var sut: Dispatcher!
    var webSocket: WebSocketMock!
    var networkMonitor: NetworkMonitoringMock!
    var socketStatusProviderMock: SocketStatusProviderMock!

    override func setUp() {
        webSocket = WebSocketMock()
        let webSocketFactory = WebSocketFactoryMock(webSocket: webSocket)
        networkMonitor = NetworkMonitoringMock()
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
        let socketConnectionHandler = ManualSocketConnectionHandler(socket: webSocket, logger: logger)
        socketStatusProviderMock = SocketStatusProviderMock()
        sut = Dispatcher(
            socketFactory: webSocketFactory,
            relayUrlFactory: relayUrlFactory, 
            networkMonitor: networkMonitor,
            socket: webSocket,
            logger: ConsoleLoggerMock(),
            socketConnectionHandler: socketConnectionHandler,
            socketStatusProvider: socketStatusProviderMock
        )
    }

    func testSendWhileConnected() {
        try! sut.connect()
        sut.send("1") {_ in}
        XCTAssertEqual(webSocket.sendCallCount, 1)
    }

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
        sut.socketConnectionStatusPublisher.sink { status in
            guard status == .connected else { return }
            expectation.fulfill()
        }.store(in: &publishers)
        socketStatusProviderMock.simulateConnectionStatus(.connected)
        waitForExpectations(timeout: 0.001)
    }

    func testOnDisconnect() throws {
        let expectation = expectation(description: "on disconnect")
        try sut.connect()
        sut.socketConnectionStatusPublisher.sink { status in
            guard status == .disconnected else { return }
            expectation.fulfill()
        }.store(in: &publishers)
        socketStatusProviderMock.simulateConnectionStatus(.disconnected)
        waitForExpectations(timeout: 0.001)
    }
}
