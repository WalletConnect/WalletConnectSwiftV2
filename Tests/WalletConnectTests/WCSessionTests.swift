import XCTest
@testable import WalletConnectAuth

final class WCSessionTests: XCTestCase {
    
    func testHasPermissionForMethod() {
        let chain = Blockchain("eip155:1")!
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [account],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertTrue(session.hasPermission(forMethod: "method", onChain: chain))
    }
    
    func testHasPermissionForMethodInExtension() {
        let chain = Blockchain("eip155:1")!
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [account],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [account],
                        methods: ["method"],
                        events: [])])
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertTrue(session.hasPermission(forMethod: "method", onChain: chain))
    }
    
    func testDenyPermissionForMethodInOtherChain() {
        let chain = Blockchain("eip155:1")!
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let cosmosAccount = Account("cosmos:cosmoshub-4:cosmos1t2uflqwqe0fsj0shcfkrvpukewcw40yjj6hdc0")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [account],
                methods: [],
                events: [],
                extensions: nil),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: ["method"],
                events: [],
                extensions: nil),
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertFalse(session.hasPermission(forMethod: "method", onChain: chain))
    }
    
    func testDenyPermissionForMethodInOtherChainExtension() {
        let chain = Blockchain("eip155:1")!
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let polyAccount = Account("eip155:137:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [account, polyAccount],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [polyAccount],
                        methods: ["method"],
                        events: [])])
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertFalse(session.hasPermission(forMethod: "method", onChain: chain))
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
        let chain = Blockchain("eip155:1")!
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [account],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [account],
                        methods: [],
                        events: ["event"])])
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertTrue(session.hasPermission(forEvent: "event", onChain: chain))
    }
    
    func testDenyPermissionForEventInOtherChain() {
        let chain = Blockchain("eip155:1")!
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let cosmosAccount = Account("cosmos:cosmoshub-4:cosmos1t2uflqwqe0fsj0shcfkrvpukewcw40yjj6hdc0")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [account],
                methods: [],
                events: [],
                extensions: nil),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: [],
                events: ["event"],
                extensions: nil),
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertFalse(session.hasPermission(forEvent: "event", onChain: chain))
    }
    
    func testDenyPermissionForEventInOtherChainExtension() {
        let chain = Blockchain("eip155:1")!
        let account = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let polyAccount = Account("eip155:137:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [account, polyAccount],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [polyAccount],
                        methods: [],
                        events: ["event"])])
        ]
        var session = WCSession.stub()
        session.updateNamespaces(namespace)
        XCTAssertFalse(session.hasPermission(forEvent: "event", onChain: chain))
    }
}
