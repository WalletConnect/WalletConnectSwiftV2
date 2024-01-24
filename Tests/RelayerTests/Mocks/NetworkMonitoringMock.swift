import Foundation
import Combine

@testable import WalletConnectRelay

class NetworkMonitoringMock: NetworkMonitoring {
    var isConnected: Bool {
        return true
    }

    var networkConnectionStatusPublisher: AnyPublisher<WalletConnectRelay.NetworkConnectionStatus, Never> {
        networkConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    
    let networkConnectionStatusPublisherSubject = CurrentValueSubject<NetworkConnectionStatus, Never>(.connected)
    
    public init() { }
}
