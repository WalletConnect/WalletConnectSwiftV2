import Foundation
import Combine

protocol WebSocketProxy: WebSocketConnecting {
    var socketCreationPublisher: AnyPublisher<WebSocketConnecting, Never> { get }
}

final class AsyncWebSocketProxy: WebSocketProxy {

    private let socketCreationSubject = PassthroughSubject<WebSocketConnecting, Never>()

    var socketCreationPublisher: AnyPublisher<WebSocketConnecting, Never> {
        return socketCreationSubject.eraseToAnyPublisher()
    }

    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?

    private var socket: WebSocketConnecting?

    private let host: String
    private let projectId: String
    private let socketFactory: WebSocketFactory
    private let socketAuthenticator: SocketAuthenticating

    init(host: String, projectId: String, socketFactory: WebSocketFactory, socketAuthenticator: SocketAuthenticating) {
        self.host = host
        self.projectId = projectId
        self.socketFactory = socketFactory
        self.socketAuthenticator = socketAuthenticator

        setUpSocket()
    }

    private func setUpSocket() {
        Task(priority: .high) { [weak self] in
            guard let self = self else { return }

            let url = await makeRelayUrl()
            let socket = socketFactory.create(with: url)

            socket.onConnect = self.onConnect
            socket.onDisconnect = self.onDisconnect
            socket.onText = self.onText

            self.socket = socket
            self.socketCreationSubject.send(socket)
        }
    }

    private func makeRelayUrl() async -> URL {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = host
        components.queryItems = [
            URLQueryItem(name: "projectId", value: projectId)
        ]
        do {
            let authToken = try await socketAuthenticator.createAuthToken()
            components.queryItems?.append(URLQueryItem(name: "auth", value: authToken))
        } catch {
            // TODO: Handle token creation errors
            print("Auth token creation error: \(error.localizedDescription)")
        }
        return components.url!
    }
}

// MARK: - WebSocketConnecting

extension AsyncWebSocketProxy: WebSocketConnecting {
    var isConnected: Bool {
        return socket?.isConnected ?? false
    }

    func connect() {
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func write(string: String, completion: (() -> Void)?) {
        socket?.write(string: string, completion: completion)
    }
}
