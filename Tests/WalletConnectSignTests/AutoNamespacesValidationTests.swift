import XCTest
@testable import WalletConnectSign

final class AutoNamespacesValidationTests: XCTestCase {
    func testAutoNamespacesSameChainRequiredAndOptional() async {
        let accounts = [Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesDifferentChainsRequiredAndOptional() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesInlineChainRequiredAndOptional() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesMultipleInlineChainRequiredAndOptional() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:3")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]

        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:3")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesMultipleInlineChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:3")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:3")!, Blockchain("eip155:4")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!, Blockchain("eip155:4")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesUnsupportedOptionalChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:3")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:4": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesPartiallySupportedOptionalChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:3")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:4": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesPartiallySupportedOptionalMethods() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesPartiallySupportedOptionalEvents() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesExtraSupportedChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
                    Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
                ],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesMultipleNamespacesRequired() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("cosmos:cosmoshub-4")!, address: "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02")!
        ]
        let requiredNamespaces = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "cosmos": ProposalNamespace(
                chains: [Blockchain("cosmos:cosmoshub-4")!],
                methods: ["cosmos_method"],
                events: ["cosmos_event"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!, Blockchain("cosmos:cosmoshub-4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "cosmos_method"],
            events: ["chainChanged", "accountsChanged", "cosmos_event"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
                    Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"]
            ),
            "cosmos": SessionNamespace(
                chains: [Blockchain("cosmos:cosmoshub-4")!],
                accounts: [
                    Account(blockchain: Blockchain("cosmos:cosmoshub-4")!, address: "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02")!
                ],
                methods: ["cosmos_method"],
                events: ["cosmos_event"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesNoSupportedRequiredChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:5")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "cosmos": ProposalNamespace(
                chains: [Blockchain("cosmos:cosmoshub-4")!],
                methods: ["cosmos_method"],
                events: ["cosmos_event"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        XCTAssertThrowsError(
            try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [Blockchain("eip155:5")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"],
                accounts: accounts
            )
        )
    }
    
    func testAutoNamespacesPartiallySupportedRequiredChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:5")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "cosmos": ProposalNamespace(
                chains: [Blockchain("cosmos:cosmoshub-4")!],
                methods: ["cosmos_method"],
                events: ["cosmos_event"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        XCTAssertThrowsError(
            try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:5")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"],
                accounts: accounts
            )
        )
    }
    
    func testAutoNamespacesNoSupportedRequiredMethods() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        XCTAssertThrowsError(
            try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign"],
                events: ["chainChanged", "accountsChanged"],
                accounts: accounts
            )
        )
    }
    
    func testAutoNamespacesNoSupportedRequiredEvents() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        XCTAssertThrowsError(
            try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"],
                accounts: accounts
            )
        )
    }
    
    func testAutoNamespacesNoAccountsForRequiredChain() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        XCTAssertThrowsError(
            try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"],
                accounts: accounts
            )
        )
    }
    
    func testAutoNamespacesPartialAccountsForRequiredChain() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"])
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        XCTAssertThrowsError(
            try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"],
                accounts: accounts
            )
        )
    }
    
    func testAutoNamespacesSameChainEmptyOptinalEvents() {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"])
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign"],
                events: []
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesSameChainEmptyRequiredEvents() {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: []
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesSameChainEmptyEvents() {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: []
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign"],
                events: []
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "personal_sign", "eth_sendTransaction"],
                events: []
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesDifferentChainEmptyOptinalEvents() {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!, address: "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"])
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign"],
                events: []
            ),
            "solana": ProposalNamespace(
                chains: [Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!],
                methods: ["solana_signMessage"],
                events: []
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "solana_signMessage", "solana_signMessage"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ],
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"]
            ),
            "solana": SessionNamespace(
                chains: [Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!],
                accounts: [
                    Account(blockchain: Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!, address: "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!,
                ],
                methods: ["solana_signMessage"],
                events: []
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }

    func testBuildThrowsWhenSessionNamespacesAreEmpty() {
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: [:], optionalNamespaces: [:])

        XCTAssertThrowsError(try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [],
            methods: [],
            events: [],
            accounts: []
        ), "Expected to throw AutoNamespacesError.emtySessionNamespacesForbidden, but it did not") { error in
            guard case AutoNamespacesError.emptySessionNamespacesForbidden = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testAutoNamespacesRequiredChainsNotSatisfied() {
        let accounts = [Account(blockchain: Blockchain("eip155:1")!, address: "0x123")!]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!], // Required chain not supported
                methods: ["personal_sign"],
                events: ["chainChanged"])
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: [:])

        XCTAssertThrowsError(try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!], // Only eip155:1 is supported
            methods: ["personal_sign"],
            events: ["chainChanged"],
            accounts: accounts
        ), "Expected to throw AutoNamespacesError.requiredChainsNotSatisfied, but it did not") { error in
            guard case AutoNamespacesError.requiredChainsNotSatisfied = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testValidatingBuiltNamespaces() async {
        // Setup
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x123")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x456")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: nil)

        do {
            // Act
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"],
                accounts: accounts
            )

            // Validate
            try Namespace.validate(sessionNamespaces)

            // Assert
            XCTAssertNotNil(sessionNamespaces, "Session namespaces should be successfully built and validated.")
        } catch {
            XCTFail("Namespace validation failed with error: \(error)")
        }
    }

    func testAutoNamespacesMergingSupersetOfMethodsAndEvents() async {
        let accounts = [Account(blockchain: Blockchain("eip155:1")!, address: "0x123")!]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_sign"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_sign"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: accounts,
                methods: ["personal_sign", "eth_sendTransaction", "eth_sign"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }

    func testAutoNamespacesWithInvalidBlockchainReferences() async {
        // Setup: Include an invalid blockchain reference in the required namespaces
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("invalid:999")!],
                methods: ["personal_sign"],
                events: ["chainChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: [:])

        // Expect the build function to throw an error due to the invalid blockchain reference
        XCTAssertThrowsError(try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!],
            methods: ["personal_sign"],
            events: ["chainChanged"],
            accounts: []
        )) { error in
            XCTAssertEqual(error as? AutoNamespacesError, AutoNamespacesError.requiredChainsNotSatisfied)
        }
    }

    func testAutoNamespacesWithAccountsAcrossDifferentBlockchains() async {
        // Setup: Accounts on different blockchains and required namespaces that span these blockchains
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x1")!,
            Account(blockchain: Blockchain("solana:4s")!, address: "0x2")!
        ]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign"],
                events: ["chainChanged"]
            ),
            "solana": ProposalNamespace(
                chains: [Blockchain("solana:4s")!],
                methods: ["solana_sign"],
                events: ["accountChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: [:])

        // Execute: Call the build function with the setup
        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("solana:4s")!],
            methods: ["personal_sign", "solana_sign"],
            events: ["chainChanged", "accountChanged"],
            accounts: accounts
        )

        // Verify: Each blockchain has its corresponding account in the session namespace
        XCTAssertTrue(sessionNamespaces["eip155"]?.accounts.contains(accounts[0]) ?? false)
        XCTAssertTrue(sessionNamespaces["solana"]?.accounts.contains(accounts[1]) ?? false)
    }

    func testAutoNamespacesWithComplexMergingAndOptionalAccounts() async {
        // Setup: Complex scenario with overlapping required and optional namespaces, including one without accounts
        let accounts = [Account(blockchain: Blockchain("eip155:1")!, address: "0x1")!]
        let requiredNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign"],
                events: ["chainChanged"]
            )
        ]
        let optionalNamespaces = [
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:1")!],
                methods: ["eth_sendTransaction"],
                events: ["accountsChanged"]
            ),
            "solana": ProposalNamespace(
                chains: [Blockchain("solana:4s")!],
                methods: ["solana_sign"],
                events: ["accountChanged"]
            )
        ]
        let sessionProposal = Session.Proposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        // Execute: Call the build function with the setup
        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("solana:4s")!],
            methods: ["personal_sign", "eth_sendTransaction", "solana_sign"],
            events: ["chainChanged", "accountsChanged", "accountChanged"],
            accounts: accounts
        )

        // Verify: Proper merging of required and optional namespaces, including method and event merging
        let eip155Namespace = sessionNamespaces["eip155"]
        XCTAssertTrue(eip155Namespace?.methods.contains("personal_sign") ?? false)
        XCTAssertTrue(eip155Namespace?.methods.contains("eth_sendTransaction") ?? false)
        XCTAssertTrue(eip155Namespace?.events.contains("chainChanged") ?? false)
        XCTAssertTrue(eip155Namespace?.events.contains("accountsChanged") ?? false)

        // Given the updated understanding, we no longer assert the presence of accounts for each namespace, allowing for 0 or more accounts.
        let solanaNamespace = sessionNamespaces["solana"]
        XCTAssertNotNil(solanaNamespace) // Verify namespace exists, but don't enforce accounts
        XCTAssertTrue(solanaNamespace?.methods.contains("solana_sign") ?? false)
        XCTAssertTrue(solanaNamespace?.events.contains("accountChanged") ?? false)
    }

}






fileprivate extension Session.Proposal {
    static func stub(
        requiredNamespaces: [String: ProposalNamespace] = [:],
        optionalNamespaces: [String: ProposalNamespace]? = nil
    ) -> Session.Proposal {
        return Session.Proposal(
            id: "mockId",
            pairingTopic: "mockPairingTopic",
            proposer: AppMetadata.stub(),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal.stub(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)
        )
    }
}

fileprivate extension SessionProposal {
    static func stub(
        requiredNamespaces: [String: ProposalNamespace] = [:],
        optionalNamespaces: [String: ProposalNamespace]? = nil,
        proposerPubKey: String = ""
    ) -> SessionProposal {
        return SessionProposal(
            relays: [],
            proposer: Participant(
                publicKey: proposerPubKey,
                metadata: AppMetadata.stub()
            ),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces ?? [:],
            sessionProperties: [:]
        )
    }
}
