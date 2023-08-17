import Foundation
import Combine
import Network

public enum NetworkConnectionStatus {
    case connected
    case notConnected
}

public protocol NetworkMonitoring: AnyObject {
    var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never> { get }
}

public final class NetworkMonitor: NetworkMonitoring {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "com.walletconnect.sdk.network.monitor")
    
    private let networkConnectionStatusPublisherSubject = CurrentValueSubject<NetworkConnectionStatus, Never>(.connected)
    
    public var networkConnectionStatusPublisher: AnyPublisher<NetworkConnectionStatus, Never> {
        networkConnectionStatusPublisherSubject
            .share()
            .eraseToAnyPublisher()
    }
    
    public init() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.networkConnectionStatusPublisherSubject.send((path.status == .satisfied) ? .connected : .notConnected)
        }
        networkMonitor.start(queue: workerQueue)
    }
}
