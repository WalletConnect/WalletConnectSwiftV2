
#if os(iOS)
import UIKit
#endif
import Foundation

class AutomaticSocketConnectionHandler: SocketConnectionHandler {
    enum Error: Swift.Error {
        case manualSocketConnectionForbidden
        case manualSocketDisconnectionForbidden
    }
    var appStateObserver: AppStateObserving
    let socket: WebSocketSessionProtocol
    private var networkMonitor: NetworkMonitoring
#if os(iOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
#endif

    init(networkMonitor: NetworkMonitoring = NetworkMonitor(),
         socket: WebSocketSessionProtocol,
         appStateObserver: AppStateObserving = AppStateObserver()) {
        self.appStateObserver = appStateObserver
        self.socket = socket
        self.networkMonitor = networkMonitor
        setUpStateObserving()
        setUpNetworkMonitoring()
        socket.connect()
    }
    
    private func setUpStateObserving() {
        appStateObserver.onWillEnterBackground = { [unowned self] in
            registerBackgroundTask()
        }
        
        appStateObserver.onWillEnterForeground = { [unowned self] in
            socket.connect()
        }
    }
    
    private func setUpNetworkMonitoring() {
        networkMonitor.onSatisfied = { [weak self] in
            self?.handleNetworkSatisfied()
        }
        networkMonitor.onUnsatisfied = { [weak self] in
            self?.handleNetworkUnsatisfied()
        }
        networkMonitor.startMonitoring()
    }
    
    func registerBackgroundTask() {
#if os(iOS)
        backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") { [weak self] in
            self?.endBackgroundTask()
        }
#endif
    }
    
    func endBackgroundTask() {
#if os(iOS)
        socket.disconnect(with: .normalClosure)
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
#endif
    }
    
    func handleConnect() throws {
        throw Error.manualSocketConnectionForbidden
    }
    
    func handleDisconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        throw Error.manualSocketDisconnectionForbidden
    }
    
    func handleNetworkUnsatisfied() {
        socket.disconnect(with: .goingAway)
    }
    
    func handleNetworkSatisfied() {
        if !socket.isConnected {
            socket.connect()
        }
    }
}

protocol BackgroundTaskRegistering {
    func register(name: String, completion: ()->())
}

class BackgroundTaskRegistrar {
    
}
