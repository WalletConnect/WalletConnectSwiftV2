import XCTest
@testable import WalletConnectSign

final class WCSessionTests: XCTestCase {

    let ethAccount = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let polyAccount = Account("eip155:137:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let cosmosAccount = Account("cosmos:cosmoshub-4:cosmos1t2uflqwqe0fsj0shcfkrvpukewcw40yjj6hdc0")!

    // MARK: Namespace Permission Tests

    func testHasPermissionForMethod() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertTrue(session.hasPermission(forMethod: "method", onChain: ethAccount.blockchain))
    }

    func testHasPermissionForMethodInExtension() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [ethAccount],
                        methods: ["method"],
                        events: [])])
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertTrue(session.hasPermission(forMethod: "method", onChain: ethAccount.blockchain))
    }

    func testDenyPermissionForMethodInOtherChain() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [],
                extensions: nil),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertFalse(session.hasPermission(forMethod: "method", onChain: ethAccount.blockchain))
    }

    func testDenyPermissionForMethodInOtherChainExtension() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [polyAccount],
                        methods: ["method"],
                        events: [])])
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertFalse(session.hasPermission(forMethod: "method", onChain: ethAccount.blockchain))
    }

    func testHasPermissionForEvent() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: ["event"],
                extensions: nil)
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertTrue(session.hasPermission(forEvent: "event", onChain: ethAccount.blockchain))
    }

    func testHasPermissionForEventInExtension() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [ethAccount],
                        methods: [],
                        events: ["event"])])
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertTrue(session.hasPermission(forEvent: "event", onChain: ethAccount.blockchain))
    }

    func testDenyPermissionForEventInOtherChain() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [],
                extensions: nil),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: [],
                events: ["event"],
                extensions: nil)
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertFalse(session.hasPermission(forEvent: "event", onChain: ethAccount.blockchain))
    }

    func testDenyPermissionForEventInOtherChainExtension() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: [],
                events: [],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [polyAccount],
                        methods: [],
                        events: ["event"])])
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertFalse(session.hasPermission(forEvent: "event", onChain: ethAccount.blockchain))
    }

    // MARK: Namespace Update Tests

    func testUpdateEqualNamespaces() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [ethAccount],
                        methods: ["method-2"],
                        events: ["event-2"])])]
        var session = WCSession.stub(namespaces: namespace)
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
    }

    func testUpdateNamespacesOverRequirement() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [ethAccount],
                        methods: ["method-2"],
                        events: ["event-2"])])]
        let newNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method", "newMethod"],
                events: ["event", "newEvent"],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [ethAccount, polyAccount],
                        methods: ["method-2", "newMethod-2"],
                        events: ["event-2", "newEvent-2"])])]
        var session = WCSession.stub(namespaces: namespace)
        XCTAssertNoThrow(try session.updateNamespaces(newNamespace))
    }

//    func testUpdateLessThanRequiredChains() {
//        let namespace = [
//            "eip155": SessionNamespace(
//                accounts: [ethAccount],
//                methods: ["method"],
//                events: ["event"],
//                extensions: [
//                    SessionNamespace.Extension(
//                        accounts: [ethAccount],
//                        methods: ["method-2"],
//                        events: ["event-2"])])]
//        var session = WCSession.stub(namespaces: namespace)
////        XCTAssertThrowsError()
//    }
    
    func testUpdateLessThanRequiredAccounts() {
        let required = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method", "method-2"],
                events: ["event", "event-2"],
                extensions: nil)]
        let invalid = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method", "method-2"],
                events: ["event", "event-2"],
                extensions: nil)]
        var session = WCSession.stub(namespaces: required)
        XCTAssertThrowsError(try session.updateNamespaces(invalid))
    }
}
