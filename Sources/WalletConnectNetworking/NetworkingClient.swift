import Foundation
import Combine

public protocol NetworkingClient {
    var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> { get }
    var logsPublisher: AnyPublisher<Log, Never> {get}
    func connect() throws
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) throws
}
