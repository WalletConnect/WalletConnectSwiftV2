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

    private var publishers = Set<AnyCancellable>()
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.automatic_socket_connection", qos: .utility, attributes: .concurrent)

    init(
        socket: WebSocketConnecting,
        networkMonitor: NetworkMonitoring = NetworkMonitor(),
        appStateObserver: AppStateObserving = AppStateObserver(),
        backgroundTaskRegistrar: BackgroundTaskRegistering = BackgroundTaskRegistrar(),
        subscriptionsTracker: SubscriptionsTracking,
        logger: ConsoleLogging
    ) {
        self.appStateObserver = appStateObserver
        self.socket = socket
        self.networkMonitor = networkMonitor
        self.backgroundTaskRegistrar = backgroundTaskRegistrar
        self.logger = logger
        self.subscriptionsTracker = subscriptionsTracker

        setUpStateObserving()
        setUpNetworkMonitoring()
    }

    func connect() {
        // Attempt to handle connection
        socket.connect()

        // Start a timer for the fallback mechanism
        let timer = DispatchSource.makeTimerSource(queue: concurrentQueue)
        timer.schedule(deadline: .now() + .seconds(defaultTimeout))
        timer.setEventHandler { [weak self] in
            guard let self = self else {
                timer.cancel()
                return
            }
            if !self.socket.isConnected {
                self.logger.debug("Connection timed out, will rety to connect...")
                retryToConnect()
            }
            timer.cancel()
        }
        timer.resume()
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

    func handleDisconnection() async {
        guard await appStateObserver.currentState == .foreground else { return }
        reconnectIfNeeded()
    }
}

