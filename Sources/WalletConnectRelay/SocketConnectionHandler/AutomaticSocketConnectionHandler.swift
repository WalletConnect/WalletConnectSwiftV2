#if os(iOS)
import UIKit
#endif
import Foundation
import Combine

class AutomaticSocketConnectionHandler {

    enum Errors: Error {
        case manualSocketConnectionForbidden, manualSocketDisconnectionForbidden
    }

    let socket: WebSocketConnecting

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
            if !socket.isConnected {
                socket.connect()
            }
        }
    }

    private func setUpNetworkMonitoring() {
        networkMonitor.onSatisfied = { [weak self] in
            self?.handleNetworkSatisfied()
        }
        networkMonitor.startMonitoring()
    }

    func registerBackgroundTask() {
        backgroundTaskRegistrar.register(name: "Finish Network Tasks") { [unowned self] in
            endBackgroundTask()
        }
    }

    func endBackgroundTask() {
        socket.disconnect()
    }

    func handleNetworkSatisfied() {
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

    func handleDisconnection() {

    }
}
