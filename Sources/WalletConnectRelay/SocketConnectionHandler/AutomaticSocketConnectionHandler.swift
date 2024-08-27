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
    private let logger: ConsoleLogging
    private let subscriptionsTracker: SubscriptionsTracking
    private let socketStatusProvider: SocketStatusProviding

    private var publishers = Set<AnyCancellable>()
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.automatic_socket_connection", qos: .utility, attributes: .concurrent)

    var reconnectionAttempts = 0
    let maxImmediateAttempts = 3
    var periodicReconnectionInterval: TimeInterval = 5.0
    var reconnectionTimer: DispatchSourceTimer?
    var isConnecting = false

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
        setUpSocketStatusObserving()
    }

    func connect() {
        // Start the connection process
        isConnecting = true
        socket.connect()
    }

    private func setUpSocketStatusObserving() {
        socketStatusProvider.socketConnectionStatusPublisher
            .sink { [unowned self] status in
                switch status {
                case .connected:
                    isConnecting = false
                    reconnectionAttempts = 0 // Reset reconnection attempts on successful connection
                    stopPeriodicReconnectionTimer() // Stop any ongoing periodic reconnection attempts
                case .disconnected:
                    if isConnecting {
                        // Handle reconnection logic
                        handleFailedConnectionAndReconnectIfNeeded()
                    } else {
                        Task(priority: .high) {
                            await handleDisconnection()
                        }
                    }
                }
            }
            .store(in: &publishers)
    }

    private func handleFailedConnectionAndReconnectIfNeeded() {
        if reconnectionAttempts < maxImmediateAttempts {
            reconnectionAttempts += 1
            logger.debug("Immediate reconnection attempt \(reconnectionAttempts) of \(maxImmediateAttempts)")
            socket.connect()
        } else {
            logger.debug("Max immediate reconnection attempts reached. Switching to periodic reconnection every \(periodicReconnectionInterval) seconds.")
            startPeriodicReconnectionTimerIfNeeded()
        }
    }

    private func stopPeriodicReconnectionTimer() {
        reconnectionTimer?.cancel()
        reconnectionTimer = nil
    }

    private func startPeriodicReconnectionTimerIfNeeded() {
        guard reconnectionTimer == nil else {return}

        reconnectionTimer = DispatchSource.makeTimerSource(queue: concurrentQueue)
        let initialDelay: DispatchTime = .now() + periodicReconnectionInterval

        reconnectionTimer?.schedule(deadline: initialDelay, repeating: periodicReconnectionInterval)

        reconnectionTimer?.setEventHandler { [unowned self] in
            logger.debug("Periodic reconnection attempt...")
            socket.connect() // Attempt to reconnect

            // The socketConnectionStatusPublisher handler will stop the timer and reset states if connection is successful
        }

        reconnectionTimer?.resume()
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
        networkMonitor.networkConnectionStatusPublisher.sink { [unowned self] networkConnectionStatus in
            if networkConnectionStatus == .connected {
                reconnectIfNeeded()
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

    func reconnectIfNeeded() {
        // Check if client has active subscriptions and only then attempt to reconnect
        if !socket.isConnected && subscriptionsTracker.isSubscribed() {
            connect()
        }
    }
}

// MARK: - SocketConnectionHandler

extension AutomaticSocketConnectionHandler: SocketConnectionHandler {
    func handleInternalConnect() async throws {
        let maxAttempts = maxImmediateAttempts
        let timeout: TimeInterval = 15
        var attempts = 0

        // Start the connection process immediately
        connect() // This will set isConnecting = true and attempt to connect

        // Use Combine publisher to monitor connection status
        let connectionStatusPublisher = socketStatusProvider.socketConnectionStatusPublisher
            .share()
            .makeConnectable()

        let connection = connectionStatusPublisher.connect()

        // Ensure connection is canceled when done
        defer { connection.cancel() }

        // Use a Combine publisher to monitor disconnection and timeout
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var cancellable: AnyCancellable?

            cancellable = connectionStatusPublisher.sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    continuation.resume() // Connection successful
                case .failure(let error):
                    continuation.resume(throwing: error) // Timeout or connection failure
                }
            }, receiveValue: { [weak self] status in
                guard let self = self else { return }

                if status == .connected {
                    continuation.resume() // Successfully connected
                } else if status == .disconnected {
                    attempts += 1
                    self.logger.debug("Disconnection observed, incrementing attempts to \(attempts)")

                    if attempts >= maxAttempts {
                        self.logger.debug("Max attempts reached. Failing with connection failed error.")
                        continuation.resume(throwing: NetworkError.connectionFailed)
                    }
                }
            })

            // Store cancellable to keep it alive
            self.publishers.insert(cancellable!)
        }
    }


    func handleConnect() throws {
        throw Errors.manualSocketConnectionForbidden
    }

    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        throw Errors.manualSocketDisconnectionForbidden
    }

    func handleDisconnection() async {
        guard await appStateObserver.currentState == .foreground else { return }
        reconnectIfNeeded()
    }
}
