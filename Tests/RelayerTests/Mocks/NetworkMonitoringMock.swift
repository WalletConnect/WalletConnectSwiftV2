
import Foundation
@testable import WalletConnectRelay

class NetworkMonitoringMock: NetworkMonitoring {
    var onSatisfied: (() -> ())?
    var onUnsatisfied: (() -> ())?
    
    func startMonitoring() { }
}
