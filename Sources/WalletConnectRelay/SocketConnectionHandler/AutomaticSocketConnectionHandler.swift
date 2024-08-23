#if os(iOS)
import UIKit
#endif
import Foundation
import Combine

class AutomaticSocketConnectionHandler {

    enum Errors: Error {
        case manualSocketConnectionForbidden, manualSocketDisconnectionForbidden
    }

    private let socket: WebSocketConnecting
    private let appStateObserver: AppStateObserving
    private let networkMonitor: NetworkMonitoring
    private let backgroundTaskRegistrar: BackgroundTaskRegistering
    private let defaultTimeout: Int = 60
    private let logger: ConsoleLogging
    private let subscriptionsTracker: SubscriptionsTracking
    private let socketStatusProvider: SocketStatusProviding

    private var publishers = Set<AnyCancellable>()
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.automatic_socket_connection", qos: .utility, attributes: .concurrent)

    private var reconnectionAttempts = 0
    private let maxImmediateAttempts = 3
    private let periodicReconnectionInterval: TimeInterval = 5.0
    private var reconnectionTimer: DispatchSourceTimer?
    private var isConnecting = false

    init(
        socket: WebSocketConnecting,
        networkMonitor: NetworkMonitoring = NetworkMonitor(),
        appStateObserver: AppStateObserving = AppStateObserver(),
        backgroundTaskRegistrar: BackgroundTaskRegistering = BackgroundTaskRegistrar(),
        subscriptionsTracker: SubscriptionsTracking,
        logger: ConsoleLogging,
        socketStatusProvider: SocketStatusProviding
    ) {
        self.appStateObserver = appStateObserver
        self.socket = socket
        self.networkMonitor = networkMonitor
        self.backgroundTaskRegistrar = backgroundTaskRegistrar
        self.logger = logger
        self.subscriptionsTracker = subscriptionsTracker
        self.socketStatusProvider = socketStatusProvider

        setUpStateObserving()
        setUpNetworkMonitoring()
    }

    func connect() {
        // Start the connection process
        isConnecting = true
        socket.connect()

        // Monitor the onConnect event to reset flags when connected
        socket.onConnect = { [unowned self] in
            isConnecting = false
            reconnectionAttempts = 0 // Reset reconnection attempts on successful connection
            stopPeriodicReconnectionTimer() // Stop any ongoing periodic reconnection attempts
        }

        // Monitor the onDisconnect event to handle reconnections
        socket.onDisconnect = { [unowned self] error in
            logger.debug("Socket disconnected: \(error?.localizedDescription ?? "Unknown error")")

            if isConnecting {
                // Handle reconnection logic
                handleFailedConnectionAndReconnectIfNeeded()
            }
        }
    }

    private func stopPeriodicReconnectionTimer() {
        reconnectionTimer?.cancel()
        reconnectionTimer = nil
    }

    private func startPeriodicReconnectionTimer() {
        reconnectionTimer?.cancel() // Cancel any existing timer
        reconnectionTimer = DispatchSource.makeTimerSource(queue: concurrentQueue)
        reconnectionTimer?.schedule(deadline: .now(), repeating: periodicReconnectionInterval)

        reconnectionTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.logger.debug("Periodic reconnection attempt...")
            self.socket.connect() // Attempt to reconnect

            // The onConnect handler will stop the timer and reset states if connection is successful
        }

        reconnectionTimer?.resume()
    }

    private func handleFailedConnectionAndReconnectIfNeeded() {
        if reconnectionAttempts < maxImmediateAttempts {
            reconnectionAttempts += 1
            logger.debug("Immediate reconnection attempt \(reconnectionAttempts) of \(maxImmediateAttempts)")
            socket.connect()
        } else {
            logger.debug("Max immediate reconnection attempts reached. Switching to periodic reconnection every \(periodicReconnectionInterval) seconds.")
            startPeriodicReconnectionTimer()
        }
    }

    private func setUpStateObserving() {
        appStateObserver.onWillEnterBackground = { [unowned self] in
            registerBackgroundTask()
        }

        appStateObserver.onWillEnterForeground = { [unowned self] in
            reconnectIfNeeded()
        }
    }

    private func setUpNetworkMonitoring() {
        networkMonitor.networkConnectionStatusPublisher.sink { [weak self] networkConnectionStatus in
            if networkConnectionStatus == .connected {
                self?.reconnectIfNeeded()
            }
        }
        .store(in: &publishers)
    }

    private func registerBackgroundTask() {
        backgroundTaskRegistrar.register(name: "Finish Network Tasks") { [unowned self] in
            endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        socket.disconnect()
    }

    private func retryToConnect() {
        if !socket.isConnected {
            connect()
        }
    }

    func reconnectIfNeeded() {

        // Check if client has active subscriptions and only then subscribe

        if !socket.isConnected && subscriptionsTracker.isSubscribed() {
            connect()
        }
    }
}

// MARK: - SocketConnectionHandler

extension AutomaticSocketConnectionHandler: SocketConnectionHandler {
    func handleInternalConnect() {
        connect()
    }
    
    func handleConnect() throws {
        throw Errors.manualSocketConnectionForbidden
    }

    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        throw Errors.manualSocketDisconnectionForbidden
    }

    no longer called from dispatcher
    func handleDisconnection() async {
        guard await appStateObserver.currentState == .foreground else { return }
        reconnectIfNeeded()
    }
}

