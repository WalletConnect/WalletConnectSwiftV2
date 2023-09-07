import Foundation
import Combine

@testable import WalletConnectRelay

class NetworkMonitoringMock: NetworkMonitoring {
    var networkConnectionStatusPublisher: AnyPublisher<WalletConnectRelay.NetworkConnectionStatus, Never> {
        networkConnectionStatusPublisherSubject.eraseToAnyPublisher()
    }
    
    let networkConnectionStatusPublisherSubject = CurrentValueSubject<NetworkConnectionStatus, Never>(.connected)
    
    public init() { }
}
