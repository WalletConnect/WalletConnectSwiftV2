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
                events: [])
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
                events: []),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: ["method"],
                events: [])
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
                events: ["event"])
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
                events: []),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: [],
                events: ["event"])
        ]
        var session = WCSession.stub()
        XCTAssertNoThrow(try session.updateNamespaces(namespace))
        XCTAssertFalse(session.hasPermission(forEvent: "event", onChain: ethAccount.blockchain))
    }

    // MARK: Namespace Update Tests

    private func stubRequiredNamespaces() -> [String: ProposalNamespace] {
        return [
            "eip155": ProposalNamespace(
                chains: [ethAccount.blockchain, polyAccount.blockchain],
                methods: ["method", "method-2"],
                events: ["event", "event-2"])]
    }

    private func stubCompliantNamespaces() -> [String: SessionNamespace] {
        return [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method", "method-2"],
                events: ["event", "event-2"])]
    }

    func testUpdateEqualNamespaces() {
        var session = WCSession.stub(requiredNamespaces: stubRequiredNamespaces())
        XCTAssertNoThrow(try session.updateNamespaces(stubCompliantNamespaces()))
    }

    func testUpdateNamespacesOverRequirement() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"])]
        let newNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method", "newMethod"],
                events: ["event", "newEvent"])]
        var session = WCSession.stub(namespaces: namespace)
        XCTAssertNoThrow(try session.updateNamespaces(newNamespace))
    }

    func testUpdateLessThanRequiredChains() {
        var session = WCSession.stub(requiredNamespaces: stubRequiredNamespaces())
        XCTAssertThrowsError(try session.updateNamespaces([:]))
    }

    func testUpdateReplaceAccount() {
        let newEthAccount = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdf")!
        let valid = [
            "eip155": SessionNamespace(
                accounts: [newEthAccount, polyAccount],
                methods: ["method", "method-2"],
                events: ["event", "event-2"])]
        var session = WCSession.stub(requiredNamespaces: stubRequiredNamespaces())
        XCTAssertNoThrow(try session.updateNamespaces(valid))
    }

    func testUpdateLessThanRequiredAccounts() {
        let invalid = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method", "method-2"],
                events: ["event", "event-2"])]
        var session = WCSession.stub(requiredNamespaces: stubRequiredNamespaces())
        XCTAssertThrowsError(try session.updateNamespaces(invalid))
    }

    func testUpdateLessThanRequiredMethods() {
        let invalid = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method"],
                events: ["event", "event-2"])]
        var session = WCSession.stub(requiredNamespaces: stubRequiredNamespaces())
        XCTAssertThrowsError(try session.updateNamespaces(invalid))
    }

    func testUpdateLessThanRequiredEvents() {
        let invalid = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method", "method-2"],
                events: ["event"])]
        var session = WCSession.stub(requiredNamespaces: stubRequiredNamespaces())
        XCTAssertThrowsError(try session.updateNamespaces(invalid))
    }
}
