import Foundation
import XCTest
@testable import WalletConnectRelay

final class AutomaticSocketConnectionHandlerTests: XCTestCase {
    var sut: AutomaticSocketConnectionHandler!
    var webSocketSession: WebSocketMock!
    var networkMonitor: NetworkMonitoringMock!
    var appStateObserver: AppStateObserverMock!
    var backgroundTaskRegistrar: BackgroundTaskRegistrarMock!
    var subscriptionsTracker: SubscriptionsTrackerMock!
    var socketStatusProviderMock: SocketStatusProviderMock!

    override func setUp() {
        webSocketSession = WebSocketMock()
        networkMonitor = NetworkMonitoringMock()
        appStateObserver = AppStateObserverMock()

        let defaults = RuntimeKeyValueStorage()
        let logger = ConsoleLoggerMock()
        let keychainStorageMock = DispatcherKeychainStorageMock()
        let clientIdStorage = ClientIdStorage(defaults: defaults, keychain: keychainStorageMock, logger: logger)

        backgroundTaskRegistrar = BackgroundTaskRegistrarMock()
        subscriptionsTracker = SubscriptionsTrackerMock()

        socketStatusProviderMock = SocketStatusProviderMock()

        sut = AutomaticSocketConnectionHandler(
            socket: webSocketSession,
            networkMonitor: networkMonitor,
            appStateObserver: appStateObserver,
            backgroundTaskRegistrar: backgroundTaskRegistrar,
            subscriptionsTracker: subscriptionsTracker,
            logger: logger,
            socketStatusProvider: socketStatusProviderMock
        )
    }

    func testConnectsOnConnectionSatisfied() {
        webSocketSession.disconnect()
        subscriptionsTracker.isSubscribedReturnValue = true // Simulate that there are active subscriptions
        XCTAssertFalse(webSocketSession.isConnected)
        networkMonitor.networkConnectionStatusPublisherSubject.send(.connected)
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testHandleConnectThrows() {
        XCTAssertThrowsError(try sut.handleConnect())
    }

    func testHandleDisconnectThrows() {
        XCTAssertThrowsError(try sut.handleDisconnect(closeCode: .normalClosure))
    }

    func testReconnectsOnEnterForeground() {
        subscriptionsTracker.isSubscribedReturnValue = true // Simulate that there are active subscriptions
        webSocketSession.disconnect()
        appStateObserver.onWillEnterForeground?()
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testReconnectsOnEnterForegroundWhenNoSubscriptions() {
        subscriptionsTracker.isSubscribedReturnValue = false // Simulate no active subscriptions
        webSocketSession.disconnect()
        appStateObserver.onWillEnterForeground?()
        XCTAssertFalse(webSocketSession.isConnected) // The connection should not be re-established
    }

    func testRegisterTaskOnEnterBackground() {
        XCTAssertNil(backgroundTaskRegistrar.completion)
        appStateObserver.onWillEnterBackground?()
        XCTAssertNotNil(backgroundTaskRegistrar.completion)
    }

    func testDisconnectOnEndBackgroundTask() {
        appStateObserver.onWillEnterBackground?()
        webSocketSession.connect()
        XCTAssertTrue(webSocketSession.isConnected)
        backgroundTaskRegistrar.completion!()
        XCTAssertFalse(webSocketSession.isConnected)
    }

    func testReconnectOnDisconnectForeground() async {
        subscriptionsTracker.isSubscribedReturnValue = true // Simulate that there are active subscriptions
        webSocketSession.connect()
        appStateObserver.currentState = .foreground
        XCTAssertTrue(webSocketSession.isConnected)
        webSocketSession.disconnect()
        await sut.handleDisconnection()
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testNotReconnectOnDisconnectForegroundWhenNoSubscriptions() async {
        subscriptionsTracker.isSubscribedReturnValue = false // Simulate no active subscriptions
        webSocketSession.connect()
        appStateObserver.currentState = .foreground
        XCTAssertTrue(webSocketSession.isConnected)
        webSocketSession.disconnect()
        await sut.handleDisconnection()
        XCTAssertFalse(webSocketSession.isConnected) // The connection should not be re-established
    }

    func testReconnectOnDisconnectBackground() async {
        subscriptionsTracker.isSubscribedReturnValue = true // Simulate that there are active subscriptions
        webSocketSession.connect()
        appStateObserver.currentState = .background
        XCTAssertTrue(webSocketSession.isConnected)
        webSocketSession.disconnect()
        await sut.handleDisconnection()
        XCTAssertFalse(webSocketSession.isConnected)
    }

    func testNotReconnectOnDisconnectBackgroundWhenNoSubscriptions() async {
        subscriptionsTracker.isSubscribedReturnValue = false // Simulate no active subscriptions
        webSocketSession.connect()
        appStateObserver.currentState = .background
        XCTAssertTrue(webSocketSession.isConnected)
        webSocketSession.disconnect()
        await sut.handleDisconnection()
        XCTAssertFalse(webSocketSession.isConnected) // The connection should not be re-established
    }

    func testReconnectIfNeededWhenSubscribed() {
        // Simulate that there are active subscriptions
        subscriptionsTracker.isSubscribedReturnValue = true

        // Ensure socket is disconnected initially
        webSocketSession.disconnect()
        XCTAssertFalse(webSocketSession.isConnected)

        // Trigger reconnect logic
        sut.reconnectIfNeeded()

        // Expect the socket to be connected since there are subscriptions
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testReconnectIfNeededWhenNotSubscribed() {
        // Simulate that there are no active subscriptions
        subscriptionsTracker.isSubscribedReturnValue = false

        // Ensure socket is disconnected initially
        webSocketSession.disconnect()
        XCTAssertFalse(webSocketSession.isConnected)

        // Trigger reconnect logic
        sut.reconnectIfNeeded()

        // Expect the socket to remain disconnected since there are no subscriptions
        XCTAssertFalse(webSocketSession.isConnected)
    }

    func testReconnectsOnConnectionSatisfiedWhenSubscribed() {
        // Simulate that there are active subscriptions
        subscriptionsTracker.isSubscribedReturnValue = true

        // Ensure socket is disconnected initially
        webSocketSession.disconnect()
        XCTAssertFalse(webSocketSession.isConnected)

        // Simulate network connection becomes satisfied
        networkMonitor.networkConnectionStatusPublisherSubject.send(.connected)

        // Expect the socket to reconnect since there are subscriptions
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testReconnectsOnEnterForegroundWhenSubscribed() {
        // Simulate that there are active subscriptions
        subscriptionsTracker.isSubscribedReturnValue = true

        // Ensure socket is disconnected initially
        webSocketSession.disconnect()
        XCTAssertFalse(webSocketSession.isConnected)

        // Simulate entering foreground
        appStateObserver.onWillEnterForeground?()

        // Expect the socket to reconnect since there are subscriptions
        XCTAssertTrue(webSocketSession.isConnected)
    }

    func testSwitchesToPeriodicReconnectionAfterMaxImmediateAttempts() {
        sut.connect() // Start connection process

        // Simulate immediate reconnection attempts
        for _ in 0...sut.maxImmediateAttempts {
            socketStatusProviderMock.simulateConnectionStatus(.disconnected)
        }

        // Now we should be switching to periodic reconnection attempts
        // Check reconnectionAttempts is set to maxImmediateAttempts
        XCTAssertEqual(sut.reconnectionAttempts, sut.maxImmediateAttempts)
        XCTAssertNotNil(sut.reconnectionTimer) // Periodic reconnection timer should be started
    }

    func testPeriodicReconnectionStopsAfterSuccessfulConnection() {
        sut.connect() // Start connection process

        // Simulate immediate reconnection attempts
        for _ in 0...sut.maxImmediateAttempts {
            socketStatusProviderMock.simulateConnectionStatus(.disconnected)
        }

        // Check that periodic reconnection starts
        XCTAssertNotNil(sut.reconnectionTimer)

        // Now simulate the connection being successful
        socketStatusProviderMock.simulateConnectionStatus(.connected)

        // Periodic reconnection timer should stop
        XCTAssertNil(sut.reconnectionTimer)
        XCTAssertEqual(sut.reconnectionAttempts, 0) // Attempts should be reset
    }

    func testPeriodicReconnectionAttempts() {
        subscriptionsTracker.isSubscribedReturnValue = true // Simulate that there are active subscriptions
        webSocketSession.disconnect()
        sut.periodicReconnectionInterval = 0.0001
        sut.connect() // Start connection process

        // Simulate immediate reconnection attempts to switch to periodic
        for _ in 0...sut.maxImmediateAttempts {
            socketStatusProviderMock.simulateConnectionStatus(.disconnected)
        }

        // Ensure we have switched to periodic reconnection
        XCTAssertNotNil(sut.reconnectionTimer)

        // Simulate the periodic timer firing without waiting for real time
        let expectation = XCTestExpectation(description: "Periodic reconnection attempt made")
        sut.reconnectionTimer?.setEventHandler {
            self.socketStatusProviderMock.simulateConnectionStatus(.connected)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        // Check that the periodic reconnection attempt was made
        XCTAssertTrue(webSocketSession.isConnected) // Assume that connection would have been attempted
    }

    func testHandleInternalConnectThrowsAfterThreeDisconnections() async {
        // Start a task to call handleInternalConnect and await its result
        let handleConnectTask = Task {
            do {
                try await sut.handleInternalConnect()
                XCTFail("Expected handleInternalConnect to throw NetworkError.connectionFailed after three disconnections")
            } catch NetworkError.connectionFailed {
                // Expected behavior
                XCTAssertEqual(sut.reconnectionAttempts, sut.maxImmediateAttempts)
            } catch {
                XCTFail("Expected NetworkError.connectionFailed, but got \(error)")
            }
        }

        let startObservingExpectation = XCTestExpectation(description: "Start observing connection status")

        // Allow handleInternalConnect() to start observing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            startObservingExpectation.fulfill()
        }
        await fulfillment(of: [startObservingExpectation], timeout: 0.02)

        // Simulate three disconnections
        for _ in 0..<sut.maxImmediateAttempts {
            socketStatusProviderMock.simulateConnectionStatus(.disconnected)
        }

        // Wait for the task to complete
        await handleConnectTask.value
    }

    func testHandleInternalConnectSuccessWithNoFailures() async {
        // Start a task to call handleInternalConnect and await its result
        let handleConnectTask = Task {
            do {
                try await sut.handleInternalConnect()
                // Success expected, do nothing
            } catch {
                XCTFail("Expected handleInternalConnect to succeed, but it threw: \(error)")
            }
        }

        // Expectation to ensure handleInternalConnect() is observing
        let startObservingExpectation = XCTestExpectation(description: "Start observing connection status")

        // Allow handleInternalConnect() to start observing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            startObservingExpectation.fulfill()
        }
        await fulfillment(of: [startObservingExpectation], timeout: 0.02)

        // Simulate a successful connection immediately
        socketStatusProviderMock.simulateConnectionStatus(.connected)

        // Wait for the task to complete
        await handleConnectTask.value

        // Verify that the state is as expected after a successful connection
        XCTAssertFalse(sut.isConnecting)
        XCTAssertNil(sut.reconnectionTimer)
        XCTAssertEqual(sut.reconnectionAttempts, 0)
    }

    func testHandleInternalConnectSuccessAfterFailures() async {
        // Start a task to call handleInternalConnect and await its result
        let handleConnectTask = Task {
            do {
                try await sut.handleInternalConnect()
                // Success expected, do nothing
            } catch {
                XCTFail("Expected handleInternalConnect to succeed after two disconnections followed by a connection, but it threw: \(error)")
            }
        }

        // Expectation to ensure handleInternalConnect() is observing
        let startObservingExpectation = XCTestExpectation(description: "Start observing connection status")

        // Allow handleInternalConnect() to start observing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            startObservingExpectation.fulfill()
        }
        await fulfillment(of: [startObservingExpectation], timeout: 0.02)

        // Simulate two disconnections
        for _ in 0..<2 {
            socketStatusProviderMock.simulateConnectionStatus(.disconnected)
        }

        // Simulate a successful connection
        socketStatusProviderMock.simulateConnectionStatus(.connected)

        // Wait for the task to complete
        await handleConnectTask.value

        // Verify that the state is as expected after a successful connection
        XCTAssertFalse(sut.isConnecting)
        XCTAssertNil(sut.reconnectionTimer)
        XCTAssertEqual(sut.reconnectionAttempts, 0) // Attempts should reset after success
    }

    func testHandleInternalConnectTimeout() async {
            // Set a short timeout for testing purposes
        sut.requestTimeout = 0.001
            // Start a task to call handleInternalConnect and await its result
            let handleConnectTask = Task {
                do {
                    try await sut.handleInternalConnect()
                    XCTFail("Expected handleInternalConnect to throw NetworkError.connectionFailed due to timeout")
                } catch NetworkError.connectionFailed {
                    // Expected behavior
                    XCTAssertEqual(sut.reconnectionAttempts, 0) // No reconnection attempts should be recorded for timeout
                } catch {
                    XCTFail("Expected NetworkError.connectionFailed due to timeout, but got \(error)")
                }
            }

            // Expectation to ensure handleInternalConnect() is observing
            let startObservingExpectation = XCTestExpectation(description: "Start observing connection status")

            // Allow handleInternalConnect() to start observing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                startObservingExpectation.fulfill()
            }
            await fulfillment(of: [startObservingExpectation], timeout: 0.02)

            // No connection simulation to allow timeout to trigger
            await handleConnectTask.value
        }
}
