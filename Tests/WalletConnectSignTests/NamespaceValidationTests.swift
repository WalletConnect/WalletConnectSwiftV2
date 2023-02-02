import XCTest
@testable import WalletConnectSign

final class NamespaceValidationTests: XCTestCase {

    let ethChain = Blockchain("eip155:1")!
    let polyChain = Blockchain("eip155:137")!
    let cosmosChain = Blockchain("cosmos:cosmoshub-4")!

    let ethAccount = Account("eip155:1:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let polyAccount = Account("eip155:137:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!
    let cosmosAccount = Account("cosmos:cosmoshub-4:cosmos1t2uflqwqe0fsj0shcfkrvpukewcw40yjj6hdc0")!

    // MARK: - Proposal namespace validation

    func testValidProposalNamespaceWithChains() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["method"],
                events: ["event"]
            ),
            "cosmos": ProposalNamespace(
                chains: [cosmosChain],
                methods: ["someMethod"],
                events: ["someEvent"]
            )
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }
    
    func testValidProposalNamespaceNoChains() {
        let namespace = [
            "eip155:1": ProposalNamespace(
                methods: ["method"],
                events: ["event"]
            )
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }
    
    func testValidProposalNamespaceMixed() {
        let namespace = [
            "eip155:1": ProposalNamespace(
                methods: ["method"],
                events: ["event"]
            ),
            "eip155": ProposalNamespace(
                chains: [polyChain],
                methods: ["someMethod"],
                events: ["someEvent"]
            )
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testChainsMustNotNotBeEmpty() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [],
                methods: ["method"],
                events: ["event"])
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    func testChainAllowsEmptyMethods() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: [],
                events: ["event"])
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testChainAllowsEmptyEvents() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["method"],
                events: [])
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAllChainsContainsNamespacePrefix() {
        let validNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, Blockchain("eip155:137")!, Blockchain("eip155:10")!],
                methods: ["method"],
                events: ["event"])
        ]
        let invalidNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, Blockchain("cosmos:cosmoshub-4")!],
                methods: ["method"],
                events: ["event"])
        ]
        XCTAssertNoThrow(try Namespace.validate(validNamespace))
        XCTAssertThrowsError(try Namespace.validate(invalidNamespace))
    }

    func testValidateAllProposalNamespaces() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["method"],
                events: ["event"]),
            "cosmos": ProposalNamespace(
                chains: [], methods: [], events: [])
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    // MARK: - Session namespace validation

    func testValidSessionNamespace() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"]
            )
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAccountsMustNotNotBeEmpty() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [],
                methods: ["method"],
                events: ["event"])
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    func testAccountAllowsEmptyMethods() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: ["event"])
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAccountAllowsEmptyEvents() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: [])
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAllAccountsContainsNamespacePrefix() {
        let validNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method"],
                events: ["event"])
        ]
        let invalidNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, cosmosAccount],
                methods: ["method"],
                events: ["event"])
        ]
        XCTAssertNoThrow(try Namespace.validate(validNamespace))
        XCTAssertThrowsError(try Namespace.validate(invalidNamespace))
    }

    func testValidateAllSessionNamespaces() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"]),
            "cosmos": SessionNamespace(
                accounts: [], methods: [], events: [])
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    // MARK: - Approval namespace validation

    func testNamespaceMustApproveAllMethods() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: [])
        ]
        let validSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign"],
                events: [])
        ]
        let invalidSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [])
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(validSessionNamespace, against: proposalNamespace))
        XCTAssertThrowsError(try Namespace.validateApproved(invalidSessionNamespace, against: proposalNamespace))
    }

    func testApprovalMustHaveAtLeastOneAccountPerProposedChain() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, polyChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        let validSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        let invalidSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(validSessionNamespace, against: proposalNamespace))
        XCTAssertThrowsError(try Namespace.validateApproved(invalidSessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayContainMultipleAccountsForSingleChain() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [
                    Account("eip155:1:0x25caCa7f7Bf3A77b1738A8c98A666dd9e4C69A0C")!,
                    Account("eip155:1:0x2Fe1cC9b1DCe6E8e16C48bc6A7ABbAB3d10DA954")!,
                    Account("eip155:1:0xEA674fdDe714fd979de3EdF0F56AA9716B898ec8")!,
                    Account("eip155:1:0xEB2F31B0224222D774541BfF89A221e7eb15a17E")!],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayExtendProposedMethodsAndEvents() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign", "personalSign"],
                events: ["accountsChanged", "someEvent"])
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayContainNonProposedChainAccounts() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"])
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMustContainAllProposedNamespaces() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"]),
            "cosmos": ProposalNamespace(
                chains: [cosmosChain],
                methods: ["cosmos_signDirect"],
                events: ["someEvent"])
        ]
        let validNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"]),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: ["cosmos_signDirect"],
                events: ["someEvent"])
        ]
        let invalidNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign", "cosmos_signDirect"],
                events: ["accountsChanged", "someEvent"])
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(validNamespace, against: proposalNamespace))
        XCTAssertThrowsError(try Namespace.validateApproved(invalidNamespace, against: proposalNamespace))
    }

    func testApprovalMustContainAllEvents() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: [],
                events: ["chainChanged"])
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [])
        ]
        XCTAssertThrowsError(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }
}
