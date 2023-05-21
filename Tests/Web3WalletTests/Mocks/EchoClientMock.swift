import Foundation
import Combine

@testable import WalletConnectEcho

final class EchoClientMock: EchoClientProtocol {
    var registedCalled = false
    
    func register(deviceToken: Data) async throws {
        registedCalled = true
    }
    
    func register(deviceToken: String) async throws {
        registedCalled = true
    }
}
