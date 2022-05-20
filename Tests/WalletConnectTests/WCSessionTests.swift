import XCTest
@testable import WalletConnectAuth

final class WCSessionTests: XCTestCase {
    
    func testHasPermissionForMethod() {
        let chain = Blockchain("eip155:1")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertTrue(session.hasPermission(forMethod: "method", onChain: chain))
    }
    
    func testHasPermissionForMethodInExtension() {
        
    }
    
    func testDenyPermissionForMethodInOtherChain() {
        
    }
    
    func testDenyPermissionForMethodInOtherChainExtension() {
        
    }
    
    func testHasPermissionForEvent() {
        let chain = Blockchain("eip155:1")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!],
                methods: [],
                events: ["event"],
                extensions: nil)
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertTrue(session.hasPermission(forEvent: "event", onChain: chain))
    }
    
    func testHasPermissionForEventInExtension() {
        
    }
    
    func testDenyPermissionForEventInOtherChain() {
        
    }
    
    func testDenyPermissionForEventInOtherChainExtension() {
        
    }
}
