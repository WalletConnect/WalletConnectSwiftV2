
import UIKit
import Foundation

protocol SocketConnectionHandler {
    var appStateObserver: AppStateObserving {get}
    func handleConnect() throws
    func handleDisconnect() throws
    func handleNetworkUnsatisfied()
    func handleNetworkSatisfied()
}

class AutomaticSocketConnectionHandler: SocketConnectionHandler {
    enum Error: Swift.Error {
        case manualSocketConnectionForbidden
        case manualSocketDisconnectionForbidden
    }
    var appStateObserver: AppStateObserving
    let socket: WebSocketSessionProtocol
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    init(socket: WebSocketSessionProtocol, appStateObserver: AppStateObserving = AppStateObserver()) {
        self.appStateObserver = appStateObserver
        self.socket = socket
        setUpStateObserving()
    }
    
    private func setUpStateObserving() {
        appStateObserver.onWillEnterBackground = {
            
        }
        appStateObserver.onWillEnterForeground = { [unowned self] in
            socket.connect()
        }
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
    
    func handleDisconnect() throws {
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
