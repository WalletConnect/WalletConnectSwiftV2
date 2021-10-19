
import Foundation
import Combine
import XCTest
@testable import WalletConnect

class WalletConnectRelayTests: XCTestCase {
    var wcRelay: WalletConnectRelay!
    var networkRelayer: MockedNetworkRelayer!
    override func setUp() {
        let logger = MuteLogger()
        wcRelay = WalletConnectRelay(networkRelayer: <#T##NetworkRelaying#>, jsonRpcSerialiser: <#T##JSONRPCSerialising#>, crypto: <#T##Crypto#>, logger: <#T##BaseLogger#>)
    }

    override func tearDown() {
        networkRelayer = nil
        networkRelayer = nil
    }
    
}

class MockedNetworkRelayer: NetworkRelaying {
    var onConnect: (() -> ())?
    
    var onMessage: ((String, String) -> ())?
    
    func publish(topic: String, payload: String, completion: @escaping ((Error?) -> ())) -> Int64 {
        <#code#>
    }
    
    func subscribe(topic: String, completion: @escaping (Error?) -> ()) -> Int64 {
        <#code#>
    }
    
    func unsubscribe(topic: String, completion: @escaping ((Error?) -> ())) -> Int64? {
        <#code#>
    }
    
    
}
