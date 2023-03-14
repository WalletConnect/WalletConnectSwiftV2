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

    private var publishers = Set<AnyCancellable>()

    init(
        socket: WebSocketConnecting,
        networkMonitor: NetworkMonitoring = NetworkMonitor(),
        appStateObserver: AppStateObserving = AppStateObserver(),
        backgroundTaskRegistrar: BackgroundTaskRegistering = BackgroundTaskRegistrar()
    ) {
        self.appStateObserver = appStateObserver
        self.socket = socket
        self.networkMonitor = networkMonitor
        self.backgroundTaskRegistrar = backgroundTaskRegistrar

        setUpStateObserving()
        setUpNetworkMonitoring()

        socket.connect()
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
        networkMonitor.onSatisfied = { [weak self] in
            self?.reconnectIfNeeded()
        }
        networkMonitor.startMonitoring()
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
