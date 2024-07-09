import Foundation
import Combine

protocol Dispatching {
    var onMessage: ((String) -> Void)? { get set }
    var isSocketConnected: Bool { get }
    var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never> { get }
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

    private let defaultTimeout: Int = 5
    private let relayUrlFactory: RelayUrlFactory
    private let networkMonitor: NetworkMonitoring
    private let logger: ConsoleLogging

    private let socketConnectionStatusPublisherSubject = CurrentValueSubject<SocketConnectionStatus, Never>(.disconnected)

    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        socketConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }

    var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never> {
        networkMonitor.networkConnectionStatusPublisher
    }

    var isSocketConnected: Bool {
        return networkMonitor.isConnected
    }

    private let concurrentQueue = DispatchQueue(label: "com.walletconnect.sdk.dispatcher", qos: .utility, attributes: .concurrent)

    init(
        socketFactory: WebSocketFactory,
        relayUrlFactory: RelayUrlFactory,
        networkMonitor: NetworkMonitoring,
        socket: WebSocketConnecting,
        logger: ConsoleLogging,
        socketConnectionHandler: SocketConnectionHandler
    ) {
        self.socketConnectionHandler = socketConnectionHandler
        self.relayUrlFactory = relayUrlFactory
        self.networkMonitor = networkMonitor
        self.logger = logger

        self.socket = socket

        super.init()
        setUpWebSocketSession()
        setUpSocketConnectionObserving()
    }

    func send(_ string: String, completion: @escaping (Error?) -> Void) {
        guard socket.isConnected else {
            completion(NetworkError.connectionFailed)
            return
        }
        socket.write(string: string) {
            completion(nil)
        }
    }

    func protectedSend(_ string: String, completion: @escaping (Error?) -> Void) {
        guard !socket.isConnected || !networkMonitor.isConnected else {
            return send(string, completion: completion)
        }

        var cancellable: AnyCancellable?
        cancellable = Publishers.CombineLatest(socketConnectionStatusPublisher, networkConnectionStatusPublisher)
            .filter { $0.0 == .connected && $0.1 == .connected }
            .setFailureType(to: NetworkError.self)
            .timeout(.seconds(defaultTimeout), scheduler: concurrentQueue, customError: { .connectionFailed })
            .sink(receiveCompletion: { [unowned self] result in
                switch result {
                case .failure(let error):
                    cancellable?.cancel()
                    completion(error)
                case .finished: break
                }
            }, receiveValue: { [unowned self] _ in
                cancellable?.cancel()
                send(string, completion: completion)
            })
    }
    

    func protectedSend(_ string: String) async throws {
        var isResumed = false
        return try await withCheckedThrowingContinuation { continuation in
            protectedSend(string) { error in
                if !isResumed {
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                    isResumed = true
                }
            }
        }
    }

    func connect() throws {
        // Attempt to handle connection
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
                self.socket.request.url = relayUrlFactory.create()
            }
            Task(priority: .high) {
                await self.socketConnectionHandler.handleDisconnection()
            }
        }
    }
}
