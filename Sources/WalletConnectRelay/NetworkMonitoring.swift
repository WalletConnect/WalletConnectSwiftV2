import Foundation
import Combine
import Network

public protocol NetworkMonitoring: AnyObject {
    var connectionStatusPublisher: AnyPublisher<Bool, Never> { get }
}

public final class NetworkMonitor: NetworkMonitoring {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "com.walletconnect.sdk.network.monitor")
    
    private let connectionStatusPublisherSubject = PassthroughSubject<Bool, Never>()
    
    public var connectionStatusPublisher: AnyPublisher<Bool, Never> {
        connectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    
    public init() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.connectionStatusPublisherSubject.send(path.status == .satisfied)
        }
        networkMonitor.start(queue: workerQueue)
    }
}
