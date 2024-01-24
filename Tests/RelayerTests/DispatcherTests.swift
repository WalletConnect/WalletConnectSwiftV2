import Foundation
import XCTest
import Combine
@testable import WalletConnectRelay
import TestingUtils
import Combine

private class DispatcherKeychainStorageMock: KeychainStorageProtocol {
    func add<T>(_ item: T, forKey key: String) throws where T : WalletConnectKMS.GenericPasswordConvertible {}
    func read<T>(key: String) throws -> T where T : WalletConnectKMS.GenericPasswordConvertible {
        return try T(rawRepresentation: Data())
    }
    func delete(key: String) throws {}
    func deleteAll() throws {}
}

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

class WebSocketFactoryMock: WebSocketFactory {
    private let webSocket: WebSocketMock
    
    init(webSocket: WebSocketMock) {
        self.webSocket = webSocket
    }
    
    func create(with url: URL) -> WebSocketConnecting {
        return webSocket
    }
}

final class DispatcherTests: XCTestCase {
    var publishers = Set<AnyCancellable>()
    var sut: Dispatcher!
    var webSocket: WebSocketMock!
    var networkMonitor: NetworkMonitoringMock!
    
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
        sut = Dispatcher(
            socketFactory: webSocketFactory,
            relayUrlFactory: relayUrlFactory, 
            networkMonitor: networkMonitor,
            socketConnectionType: .manual,
            logger: ConsoleLoggerMock()
        )
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
        sut.socketConnectionStatusPublisher.sink { status in
            guard status == .connected else { return }
            expectation.fulfill()
        }.store(in: &publishers)
        webSocket.onConnect?()
        waitForExpectations(timeout: 0.001)
    }

    func testOnDisconnect() throws {
        let expectation = expectation(description: "on disconnect")
        try sut.connect()
        sut.socketConnectionStatusPublisher.sink { status in
            guard status == .disconnected else { return }
            expectation.fulfill()
        }.store(in: &publishers)
        webSocket.onDisconnect?(nil)
        waitForExpectations(timeout: 0.001)
    }
}
