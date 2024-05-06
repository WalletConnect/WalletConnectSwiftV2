import Foundation
import Combine

protocol Dispatching {
    var onMessage: ((String) -> Void)? { get set }
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    func send(_ string: String, completion: @escaping (Error?) -> Void)
    func protectedSend(_ string: String, completion: @escaping (Error?) -> Void)
    func protectedSend(_ string: String) async throws
    func connect() throws
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
}

final class Dispatcher: NSObject, Dispatching {
    var onMessage: ((String) -> Void)?
    var socket: WebSocketConnecting
    var socketConnectionHandler: SocketConnectionHandler
    
    private let relayUrlFactory: RelayUrlFactory
    private let logger: ConsoleLogging
    
    private let defaultTimeout: Int = 10
    /// The property is used to determine whether relay.walletconnect.org will be used
    /// in case relay.walletconnect.com doesn't respond for some reason (most likely due to being blocked in the user's location).
    private var fallback = false
    
    private let socketConnectionStatusPublisherSubject = CurrentValueSubject<SocketConnectionStatus, Never>(.disconnected)

    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.dispatcher", attributes: .concurrent)

    init(
        socketFactory: WebSocketFactory,
        relayUrlFactory: RelayUrlFactory,
        socketConnectionType: SocketConnectionType,
        logger: ConsoleLogging
    ) {
        self.relayUrlFactory = relayUrlFactory
        self.logger = logger
        
        let socket = socketFactory.create(with: relayUrlFactory.create(fallback: fallback))
        socket.request.addValue(EnvironmentInfo.userAgent, forHTTPHeaderField: "User-Agent")
        self.socket = socket
        
        switch socketConnectionType {
        case .automatic:    socketConnectionHandler = AutomaticSocketConnectionHandler(socket: socket)
        case .manual:       socketConnectionHandler = ManualSocketConnectionHandler(socket: socket)
        }
        
        super.init()
        setUpWebSocketSession()
        setUpSocketConnectionObserving()
    }

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        guard socket.isConnected else {
            completion(NetworkError.webSocketNotConnected)
            return
        }
        socket.write(string: string) {
            completion(nil)
        }
    }

    func protectedSend(_ string: String, completion: @escaping (Error?) -> Void) {
        guard !socket.isConnected else {
            return send(string, completion: completion)
        }

        var cancellable: AnyCancellable?
        cancellable = socketConnectionStatusPublisher
            .filter { $0 == .connected }
            .setFailureType(to: NetworkError.self)
            .timeout(.seconds(defaultTimeout), scheduler: concurrentQueue, customError: { .webSocketNotConnected })
            .sink(receiveCompletion: { [unowned self] result in
                switch result {
                case .failure(let error):
                    cancellable?.cancel()
                    self.handleFallbackIfNeeded(error: error)
                    completion(error)
                case .finished: break
                }
            }, receiveValue: { [unowned self] _ in
                cancellable?.cancel()
                send(string, completion: completion)
            })
    }

    func protectedSend(_ string: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            protectedSend(string) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func connect() throws {
        try socketConnectionHandler.handleConnect()
    }

    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws {
        try socketConnectionHandler.handleDisconnect(closeCode: closeCode)
    }
}

// MARK: - Private functions
extension Dispatcher {
    private func setUpWebSocketSession() {
        socket.onText = { [unowned self] in
            self.onMessage?($0)
        }
    }

    private func setUpSocketConnectionObserving() {
        socket.onConnect = { [unowned self] in
            self.socketConnectionStatusPublisherSubject.send(.connected)
        }
        socket.onDisconnect = { [unowned self] error in
            self.socketConnectionStatusPublisherSubject.send(.disconnected)
            if error != nil {
                self.socket.request.url = relayUrlFactory.create(fallback: fallback)
            }
            Task(priority: .high) {
                await self.socketConnectionHandler.handleDisconnection()
            }
        }
    }
    
    private func handleFallbackIfNeeded(error: NetworkError) {
        if error == .webSocketNotConnected && socket.request.url?.host == NetworkConstants.defaultUrl {
            logger.debug("[WebSocket] - Fallback to \(NetworkConstants.fallbackUrl)")
            fallback = true
            socket.request.url = relayUrlFactory.create(fallback: fallback)
            Task(priority: .high) {
                await self.socketConnectionHandler.handleDisconnection()
            }
        }
    }
}
