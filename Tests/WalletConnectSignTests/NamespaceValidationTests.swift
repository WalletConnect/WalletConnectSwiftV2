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

    func testValidProposalNamespace() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    ProposalNamespace.Extension(chains: [Blockchain("eip155:137")!], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            ),
            "cosmos": ProposalNamespace(
                chains: [cosmosChain],
                methods: ["someMethod"],
                events: ["someEvent"],
                extensions: nil
            )
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testChainsMustNotNotBeEmpty() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    func testChainAllowsEmptyMethods() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: [],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testChainAllowsEmptyEvents() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAllChainsContainsNamespacePrefix() {
        let validNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, Blockchain("eip155:137")!, Blockchain("eip155:10")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        let invalidNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, Blockchain("cosmos:cosmoshub-4")!],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(validNamespace))
        XCTAssertThrowsError(try Namespace.validate(invalidNamespace))
    }

    func testExtensionChainsMustNotBeEmpty() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    ProposalNamespace.Extension(chains: [], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            )
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    func testValidateAllProposalNamespaces() {
        let namespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["method"],
                events: ["event"],
                extensions: nil),
            "cosmos": ProposalNamespace(
                chains: [], methods: [], events: [], extensions: nil)
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    // MARK: - Session namespace validation

    func testValidSessionNamespace() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    SessionNamespace.Extension(accounts: [polyAccount], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            )
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAccountsMustNotNotBeEmpty() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    func testAccountAllowsEmptyMethods() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAccountAllowsEmptyEvents() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: [],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(namespace))
    }

    func testAllAccountsContainsNamespacePrefix() {
        let validNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        let invalidNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, cosmosAccount],
                methods: ["method"],
                events: ["event"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validate(validNamespace))
        XCTAssertThrowsError(try Namespace.validate(invalidNamespace))
    }

    func testExtensionAccountsMustNotBeEmpty() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"],
                extensions: [
                    SessionNamespace.Extension(accounts: [], methods: ["otherMethod"], events: ["otherEvent"])
                ]
            )
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    func testValidateAllSessionNamespaces() {
        let namespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["method"],
                events: ["event"],
                extensions: nil),
            "cosmos": SessionNamespace(
                accounts: [], methods: [], events: [], extensions: nil)
        ]
        XCTAssertThrowsError(try Namespace.validate(namespace))
    }

    // MARK: - Approval namespace validation

    func testNamespaceMustApproveAllMethods() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: [],
                extensions: nil)
        ]
        let validSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign"],
                events: [],
                extensions: nil)
        ]
        let invalidSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(validSessionNamespace, against: proposalNamespace))
        XCTAssertThrowsError(try Namespace.validateApproved(invalidSessionNamespace, against: proposalNamespace))
    }

    func testApprovalMustHaveAtLeastOneAccountPerProposedChain() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, polyChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        let validSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        let invalidSessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(validSessionNamespace, against: proposalNamespace))
        XCTAssertThrowsError(try Namespace.validateApproved(invalidSessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayContainMultipleAccountsForSingleChain() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [
                    Account("eip155:1:0x25caCa7f7Bf3A77b1738A8c98A666dd9e4C69A0C")!,
                    Account("eip155:1:0x2Fe1cC9b1DCe6E8e16C48bc6A7ABbAB3d10DA954")!,
                    Account("eip155:1:0xEA674fdDe714fd979de3EdF0F56AA9716B898ec8")!,
                    Account("eip155:1:0xEB2F31B0224222D774541BfF89A221e7eb15a17E")!],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayExtendProposedMethodsAndEvents() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign", "personalSign"],
                events: ["accountsChanged", "someEvent"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayContainNonProposedChainAccounts() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMustContainAllProposedNamespaces() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil),
            "cosmos": ProposalNamespace(
                chains: [cosmosChain],
                methods: ["cosmos_signDirect"],
                events: ["someEvent"],
                extensions: nil)
        ]
        let validNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil),
            "cosmos": SessionNamespace(
                accounts: [cosmosAccount],
                methods: ["cosmos_signDirect"],
                events: ["someEvent"],
                extensions: nil)
        ]
        let invalidNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: ["eth_sign", "cosmos_signDirect"],
                events: ["accountsChanged", "someEvent"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(validNamespace, against: proposalNamespace))
        XCTAssertThrowsError(try Namespace.validateApproved(invalidNamespace, against: proposalNamespace))
    }

    func testExtensionsMayBeMerged() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, polyChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: [
                    ProposalNamespace.Extension(chains: [polyChain], methods: ["personalSign"], events: [])
                ]
            )
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged", "personalSign"],
                extensions: nil)
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMustContainAllEvents() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain],
                methods: [],
                events: ["chainChanged"],
                extensions: nil)
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount],
                methods: [],
                events: [],
                extensions: nil)
        ]
        XCTAssertThrowsError(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayExtendoMethodsAndEventsInExtensions() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, polyChain],
                methods: [],
                events: ["chainChanged"],
                extensions: [
                    ProposalNamespace.Extension(chains: [polyChain], methods: ["eth_sign"], events: [])
                ]
            )
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: [],
                events: ["chainChanged"],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [polyAccount],
                        methods: ["eth_sign", "personalSign"],
                        events: ["accountsChanged"]
                    )
                ]
            )
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalExtensionsMayContainAccountsNotDefinedInProposal() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, polyChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: [
                    ProposalNamespace.Extension(chains: [polyChain], methods: ["personalSign"], events: [])
                ]
            )
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [polyAccount, Account("eip155:42:0xab16a96d359ec26a11e2c2b3d8f8b8942d5bfcdb")!],
                        methods: ["personalSign"],
                        events: []
                    )
                ]
            )
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }

    func testApprovalMayAddExtensionsNotDefinedInProposal() {
        let proposalNamespace = [
            "eip155": ProposalNamespace(
                chains: [ethChain, polyChain],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: nil)
        ]
        let sessionNamespace = [
            "eip155": SessionNamespace(
                accounts: [ethAccount, polyAccount],
                methods: ["eth_sign"],
                events: ["accountsChanged"],
                extensions: [
                    SessionNamespace.Extension(
                        accounts: [polyAccount],
                        methods: ["personalSign"],
                        events: ["accountsChanged"]
                    )
                ]
            )
        ]
        XCTAssertNoThrow(try Namespace.validateApproved(sessionNamespace, against: proposalNamespace))
    }
}
