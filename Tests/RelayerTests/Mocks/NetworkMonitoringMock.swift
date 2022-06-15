import Foundation
@testable import WalletConnectRelay

class NetworkMonitoringMock: NetworkMonitoring {
    var onSatisfied: (() -> Void)?
    var onUnsatisfied: (() -> Void)?

    func startMonitoring() { }
}
