
import Foundation
import XCTest
@testable import WalletConnect

final class ClientTests: XCTestCase {
    
    let url = URL(string: "wss://staging.walletconnect.org")!

    func makeClient() -> Relay {
        let transport = JSONRPCTransport(url: url)
        return Relay(transport: transport, crypto: Crypto())
    }
    
    func testSettlePairing() {
        
    }
}
