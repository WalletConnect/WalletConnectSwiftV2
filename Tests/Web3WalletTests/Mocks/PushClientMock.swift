import Foundation
import Combine

@testable import WalletConnectPush

final class PushClientMock: PushClientProtocol {
    var registedCalled = false
    
    func register(deviceToken: Data) async throws {
        registedCalled = true
    }
    
    func register(deviceToken: String) async throws {
        registedCalled = true
    }
}
