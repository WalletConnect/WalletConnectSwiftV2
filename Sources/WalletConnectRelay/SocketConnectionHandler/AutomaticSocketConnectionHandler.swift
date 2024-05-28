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
    private let defaultTimeout: Int = 5
    private let logger: ConsoleLogging
    private var socketUrlFallbackHandler: SocketUrlFallbackHandler

    private var publishers = Set<AnyCancellable>()
    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.automatic_socket_connection", qos: .utility, attributes: .concurrent)

    init(
        socket: WebSocketConnecting,
        networkMonitor: NetworkMonitoring = NetworkMonitor(),
        appStateObserver: AppStateObserving = AppStateObserver(),
        backgroundTaskRegistrar: BackgroundTaskRegistering = BackgroundTaskRegistrar(),
        logger: ConsoleLogging,
        socketUrlFallbackHandler: SocketUrlFallbackHandler
    ) {
        self.appStateObserver = appStateObserver
        self.socket = socket
        self.networkMonitor = networkMonitor
        self.backgroundTaskRegistrar = backgroundTaskRegistrar
        self.logger = logger
        self.socketUrlFallbackHandler = socketUrlFallbackHandler

        setUpStateObserving()
        setUpNetworkMonitoring()

        socketUrlFallbackHandler.onTryReconnect = { [unowned self] in
            Task(priority: .high) {
                await tryReconect()
            }
        }

        connect()

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
                self.logger.debug("Connection timed out, initiating fallback...")
                self.socketUrlFallbackHandler.handleFallbackIfNeeded(error: .connectionFailed)
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

    private func reconnectIfNeeded() {
        if !socket.isConnected {
            socket.connect()
        }
    }
}

// MARK: - SocketConnectionHandler

extension AutomaticSocketConnectionHandler: SocketConnectionHandler {
    func tryReconect() async {
        guard await appStateObserver.currentState == .foreground else { return }
        reconnectIfNeeded()
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
