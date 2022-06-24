import Foundation
import Network

protocol NetworkMonitoring {
    var onSatisfied: (() -> Void)? {get set}
    var onUnsatisfied: (() -> Void)? {get set}
    func startMonitoring()
}

class NetworkMonitor: NetworkMonitoring {
    var onSatisfied: (() -> Void)?
    var onUnsatisfied: (() -> Void)?

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.walletconnect.sdk.network.monitor")

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.onSatisfied?()
            } else {
                self?.onUnsatisfied?()
            }
        }
        monitor.start(queue: monitorQueue)
    }
}
