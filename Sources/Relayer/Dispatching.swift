import Foundation
import WalletConnectUtils

protocol Dispatching {
    var onConnect: (()->())? {get set}
    var onDisconnect: (()->())? {get set}
    var onMessage: ((String) -> ())? {get set}
    func send(_ string: String, completion: @escaping (Error?)->())
    func connect()
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode)
}

final class Dispatcher: NSObject, Dispatching {
    var onConnect: (() -> ())?
    var onDisconnect: (() -> ())?
    var onMessage: ((String) -> ())?
    private var textFramesQueue = Queue<String>()
    private var networkMonitor: NetworkMonitoring
    private let url: URL
    var socket: WebSocketSessionProtocol
    var socketConnectionObserver: SocketConnectionObserving
    
    init(url: URL,
         networkMonitor: NetworkMonitoring = NetworkMonitor(),
         socket: WebSocketSessionProtocol,
         socketConnectionObserver: SocketConnectionObserving,
         socketConnectionHandler: SocketConnectionHandler) {
        self.url = url
        self.networkMonitor = networkMonitor
        self.socket = socket
        self.socketConnectionObserver = socketConnectionObserver
        super.init()
        setUpWebSocketSession()
        setUpSocketConnectionObserving()
        setUpNetworkMonitoring()
        socket.connect(on: url)
    }

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        if socket.isConnected {
            self.socket.send(string, completionHandler: completion)
            //TODO - enqueue     if fails
        } else {
            textFramesQueue.enqueue(string)
        }
    }
    
    func connect() {
        if !socket.isConnected {
            socket.connect(on: url)
        }
    }
    
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) {
        socket.disconnect(with: closeCode)
    }
    
    private func setUpWebSocketSession() {
        socket.onMessageReceived = { [weak self] in
            self?.onMessage?($0)
        }
        socket.onMessageError = { error in
            print(error)
        }
    }
    
    private func setUpSocketConnectionObserving() {
        socketConnectionObserver.onConnect = { [weak self] in
            self?.dequeuePendingTextFrames()
            self?.onConnect?()
        }
        socketConnectionObserver.onDisconnect = { [weak self] in
            self?.onDisconnect?()
        }
    }
    
    private func setUpNetworkMonitoring() {
        networkMonitor.onSatisfied = { [weak self] in
            self?.connect()
        }
        networkMonitor.onUnsatisfied = { [weak self] in
            self?.disconnect(closeCode: .goingAway)
        }
        networkMonitor.startMonitoring()
    }
    
    private func dequeuePendingTextFrames() {
        while let frame = textFramesQueue.dequeue() {
            send(frame) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
}


protocol SocketConnectionHandler {
    var appStateObserver: AppStateObserving {get}
    func handleConnect() throws
    func handleDisconnect() throws
    func handleNetworkUnsatisfied() throws
    func handleNetworkSatisfied(_ url: URL)
}


import UIKit
class AutomaticSocketConnectionHandler: SocketConnectionHandler {
    enum Error: Swift.Error {
        case manualSocketConnectionForbidden
        case manualSocketDisconnectionForbidden
    }
    var appStateObserver: AppStateObserving
    let socket: WebSocketSessionProtocol
    let url: URL
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    init(socket: WebSocketSessionProtocol, url: URL, appStateObserver: AppStateObserving = AppStateObserver()) {
        self.appStateObserver = appStateObserver
        self.socket = socket
        self.url = url
        setUpStateObserving()
    }
    
    private func setUpStateObserving() {
        appStateObserver.onWillEnterBackground = {
            
        }
        appStateObserver.onWillEnterForeground = { [unowned self] in
            socket.connect(on: url)
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
    
    func handleNetworkSatisfied(_ url: URL) {
        if !socket.isConnected {
            socket.connect(on: url)
        }
    }
}
