import XCTest
@testable import WalletConnectSign
@testable import OrderedCollections

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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet(accounts),
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet([
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
                    Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ]),
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            ),
            "eip155:2": ProposalNamespace(
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet([
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ]),
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet([
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ]),
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
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
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
                accounts: OrderedSet([
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ]),
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "personal_sign", "eth_sendTransaction"],
                events: []
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testAutoNamespacesDifferentChainEmptyOptinalEvents() {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!, address: "4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!
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
                chains: [Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!],
                methods: ["solana_signMessage"],
                events: []
            )
        ]
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: []),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [])), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        let sessionNamespaces = try! AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [Blockchain("eip155:1")!, Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "solana_signMessage", "solana_signMessage"],
            events: ["chainChanged", "accountsChanged"],
            accounts: accounts
        )
        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: OrderedSet([
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
                ]),
                methods: ["eth_signTypedData_v4", "eth_signTransaction", "eth_signTypedData", "eth_sign", "personal_sign", "eth_sendTransaction"],
                events: ["chainChanged", "accountsChanged"]
            ),
            "solana": SessionNamespace(
                chains: [Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!],
                accounts: OrderedSet([
                    Account(blockchain: Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!, address: "4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!,
                ]),
                methods: ["solana_signMessage"],
                events: []
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
}
