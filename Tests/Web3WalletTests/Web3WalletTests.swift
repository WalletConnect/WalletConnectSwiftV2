import XCTest
import Combine

@testable import Auth
@testable import Web3Wallet

final class Web3WalletTests: XCTestCase {
    var web3WalletClient: Web3WalletClient!
    var authClient: AuthClientMock!
    var signClient: SignClientMock!
    var pairingClient: PairingClientMock!
    var echoClient: EchoClientMock!

    private var disposeBag = Set<AnyCancellable>()
    
    override func setUp() {
        authClient = AuthClientMock()
        signClient = SignClientMock()
        pairingClient = PairingClientMock()
        echoClient = EchoClientMock()
        
        web3WalletClient = Web3WalletClientFactory.create(
            authClient: authClient,
            signClient: signClient,
            pairingClient: pairingClient,
            echoClient: echoClient
        )
    }
    
    func testSessionRequestCalled() {
        var success = false
        web3WalletClient.sessionRequestPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testAuthRequestCalled() {
        var success = false
        web3WalletClient.authRequestPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSessionProposalCalled() {
        var success = false
        web3WalletClient.sessionProposalPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSessionsCalled() {
        var success = false
        web3WalletClient.sessionsPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSocketConnectionStatusCalled() {
        var success = false
        web3WalletClient.socketConnectionStatusPublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSessionSettleCalled() {
        var success = false
        web3WalletClient.sessionSettlePublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSessionDeleteCalled() {
        var success = false
        web3WalletClient.sessionDeletePublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testSessionResponseCalled() {
        var success = false
        web3WalletClient.sessionResponsePublisher.sink { value in
            success = true
            XCTAssertTrue(true)
        }
        .store(in: &disposeBag)
        
        let expectation = expectation(description: "Fail after 0.1s timeout")
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut && success == false {
            XCTFail()
        }
    }
    
    func testApprovedNamespacesSameChainRequiredAndOptional() async {
        let accounts = [Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:1")!],
                    methods: ["personal_sign"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:1")!],
                    methods: ["eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesDifferentChainsRequiredAndOptional() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:1")!],
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:2")!],
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesInlineChainRequiredAndOptional() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:2")!],
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesMultipleInlineChainRequiredAndOptional() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:3")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:2": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:3")!],
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesMultipleInlineChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:3")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:2": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:3")!],
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:4": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:3")!, Blockchain("eip155:4")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesUnsupportedOptionalChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:2": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:3")!],
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:4": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesPartiallySupportedOptionalChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:2": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:3")!],
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:4": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesPartiallySupportedOptionalMethods() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:2": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                    methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                    events: ["chainChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesPartiallySupportedOptionalEvents() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:2": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                    methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                    events: ["chainChanged", "accountsChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged", "accountsChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesExtraSupportedChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "eip155:2": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                    methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                    events: ["chainChanged", "accountsChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
            events: ["chainChanged", "accountsChanged"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: Set(accounts),
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesMultipleNamespacesRequired() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("cosmos:cosmoshub-4")!, address: "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02")!
        ]
        
        let sessionNamespaces = try! web3WalletClient.buildApprovedNamespaces(
            requiredNamespaces: [
                "eip155:1": ProposalNamespace(
                    methods: ["personal_sign", "eth_sendTransaction"],
                    events: ["chainChanged"]
                ),
                "cosmos": ProposalNamespace(
                    chains: [Blockchain("cosmos:cosmoshub-4")!],
                    methods: ["cosmos_method"],
                    events: ["cosmos_event"]
                )
            ],
            optionalNamespaces: [
                "eip155": ProposalNamespace(
                    chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                    methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                    events: ["chainChanged", "accountsChanged"]
                )
            ],
            chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!, Blockchain("eip155:4")!, Blockchain("cosmos:cosmoshub-4")!],
            methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "cosmos_method"],
            events: ["chainChanged", "accountsChanged", "cosmos_event"],
            accounts: Set(accounts)
        )

        let expectedNamespaces: [String: SessionNamespace] = [
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                accounts: Set([
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
                    Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
                    Account(blockchain: Blockchain("eip155:4")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
                ]),
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"]
            ),
            "cosmos": SessionNamespace(
                chains: [Blockchain("cosmos:cosmoshub-4")!],
                accounts: Set([
                    Account(blockchain: Blockchain("cosmos:cosmoshub-4")!, address: "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02")!
                ]),
                methods: ["cosmos_method"],
                events: ["cosmos_event"]
            )
        ]
        
        XCTAssertEqual(sessionNamespaces, expectedNamespaces)
    }
    
    func testApprovedNamespacesNoSupportedRequiredChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:5")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        XCTAssertThrowsError(
            try web3WalletClient.buildApprovedNamespaces(
                requiredNamespaces: [
                    "eip155:1": ProposalNamespace(
                        methods: ["personal_sign", "eth_sendTransaction"],
                        events: ["chainChanged"]
                    ),
                    "cosmos": ProposalNamespace(
                        chains: [Blockchain("cosmos:cosmoshub-4")!],
                        methods: ["cosmos_method"],
                        events: ["cosmos_event"]
                    )
                ],
                optionalNamespaces: [
                    "eip155": ProposalNamespace(
                        chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                        methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                        events: ["chainChanged", "accountsChanged"]
                    )
                ],
                chains: [Blockchain("eip155:5")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"],
                accounts: Set(accounts)
            )
        )
    }
    
    func testApprovedNamespacesPartiallySupportedRequiredChains() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!,
            Account(blockchain: Blockchain("eip155:5")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        XCTAssertThrowsError(
            try web3WalletClient.buildApprovedNamespaces(
                requiredNamespaces: [
                    "eip155:1": ProposalNamespace(
                        methods: ["personal_sign", "eth_sendTransaction"],
                        events: ["chainChanged"]
                    ),
                    "cosmos": ProposalNamespace(
                        chains: [Blockchain("cosmos:cosmoshub-4")!],
                        methods: ["cosmos_method"],
                        events: ["cosmos_event"]
                    )
                ],
                optionalNamespaces: [
                    "eip155": ProposalNamespace(
                        chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                        methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                        events: ["chainChanged", "accountsChanged"]
                    )
                ],
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:5")!],
                methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction"],
                events: ["chainChanged", "accountsChanged"],
                accounts: Set(accounts)
            )
        )
    }
    
    func testApprovedNamespacesNoSupportedRequiredMethods() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:1")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        XCTAssertThrowsError(
            try web3WalletClient.buildApprovedNamespaces(
                requiredNamespaces: [
                    "eip155:1": ProposalNamespace(
                        methods: ["personal_sign", "eth_sendTransaction"],
                        events: ["chainChanged"]
                    )
                ],
                optionalNamespaces: [
                    "eip155": ProposalNamespace(
                        chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                        methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                        events: ["chainChanged", "accountsChanged"]
                    )
                ],
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign"],
                events: ["chainChanged", "accountsChanged"],
                accounts: Set(accounts)
            )
        )
    }
    
    func testApprovedNamespacesNoAccountsForRequiredChain() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        XCTAssertThrowsError(
            try web3WalletClient.buildApprovedNamespaces(
                requiredNamespaces: [
                    "eip155:1": ProposalNamespace(
                        methods: ["personal_sign", "eth_sendTransaction"],
                        events: ["chainChanged"]
                    )
                ],
                optionalNamespaces: [
                    "eip155": ProposalNamespace(
                        chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                        methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                        events: ["chainChanged", "accountsChanged"]
                    )
                ],
                chains: [Blockchain("eip155:1")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"],
                accounts: Set(accounts)
            )
        )
    }
    
    func testApprovedNamespacesPartialAccountsForRequiredChain() async {
        let accounts = [
            Account(blockchain: Blockchain("eip155:2")!, address: "0x57f48fAFeC1d76B27e3f29b8d277b6218CDE6092")!
        ]
        
        XCTAssertThrowsError(
            try web3WalletClient.buildApprovedNamespaces(
                requiredNamespaces: [
                    "eip155:1": ProposalNamespace(
                        methods: ["personal_sign", "eth_sendTransaction"],
                        events: ["chainChanged"]
                    ),
                    "eip155:2": ProposalNamespace(
                        methods: ["personal_sign", "eth_sendTransaction"],
                        events: ["chainChanged"]
                    )
                ],
                optionalNamespaces: [
                    "eip155": ProposalNamespace(
                        chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                        methods: ["personal_sign", "eth_sendTransaction", "eth_signTransaction", "eth_signTypedData"],
                        events: ["chainChanged", "accountsChanged"]
                    )
                ],
                chains: [Blockchain("eip155:1")!, Blockchain("eip155:2")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["chainChanged"],
                accounts: Set(accounts)
            )
        )
    }
    
    func testApproveCalled() async {
        try! await web3WalletClient.approve(proposalId: "", namespaces: [:])
        XCTAssertTrue(signClient.approveCalled)
    }
    
    func testRejectSessionCalled() async {
        try! await web3WalletClient.reject(proposalId: "", reason: .userRejected)
        XCTAssertTrue(signClient.rejectCalled)
    }
    
    func testRejectAuthRequestCalled() async {
        try! await web3WalletClient.reject(requestId: .left(""))
        XCTAssertTrue(authClient.rejectCalled)
    }
    
    func testUpdateCalled() async {
        try! await web3WalletClient.update(topic: "", namespaces: [:])
        XCTAssertTrue(signClient.updateCalled)
    }
    
    func testExtendCalled() async {
        try! await web3WalletClient.extend(topic: "")
        XCTAssertTrue(signClient.extendCalled)
    }
    
    func testSignRespondCalled() async {
        try! await web3WalletClient.respond(
            topic: "",
            requestId: .left(""),
            response: RPCResult.response(AnyCodable(true))
        )
        XCTAssertTrue(signClient.respondCalled)
    }
    
    func testPairCalled() async {
        try! await web3WalletClient.pair(uri: WalletConnectURI(
            topic: "topic",
            symKey: "symKey",
            relay: RelayProtocolOptions(protocol: "", data: "")
        ))
        XCTAssertTrue(pairingClient.pairCalled)
    }
    
    func testDisconnectPairingCalled() async {
        try! await web3WalletClient.disconnectPairing(topic: "topic")
        XCTAssertTrue(pairingClient.disconnectPairingCalled)
    }
    
    func testDisconnectCalled() async {
        try! await web3WalletClient.disconnect(topic: "")
        XCTAssertTrue(signClient.disconnectCalled)
    }
    
    func testGetSessionsCalledAndNotEmpty() {
        let sessions = web3WalletClient.getSessions()
        XCTAssertEqual(1, sessions.count)
    }
    
    func testFormatMessageCalled() {
        let authPayload = AuthPayload(
            requestParams: RequestParams(
                domain: "service.invalid",
                chainId: "eip155:1",
                nonce: "32891756",
                aud: "https://service.invalid/login",
                nbf: nil,
                exp: nil,
                statement: "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
                requestId: nil,
                resources: [
                    "ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/",
                    "https://example.com/my-web2-claim.json"
                ]
            ),
            iat: "2021-09-30T16:25:24Z"
        )
        
        let formattedMessage = try! web3WalletClient.formatMessage(
            payload: authPayload,
            address: ""
        )
        XCTAssertEqual("formatted_message", formattedMessage)
    }
    
    func testAuthRespondCalled() async {
        let signature = CacaoSignature(t: .eip191, s: "0x438effc459956b57fcd9f3dac6c675f9cee88abf21acab7305e8e32aa0303a883b06dcbd956279a7a2ca21ffa882ff55cc22e8ab8ec0f3fe90ab45f306938cfa1b")
        let account = Account("eip155:56:0xe5EeF1368781911d265fDB6946613dA61915a501")!
        
        try! await web3WalletClient.respond(
            requestId: .left(""),
            signature: signature,
            from: account
        )
        XCTAssertTrue(authClient.respondCalled)
    }
    
    func testSignPendingRequestsCalledAndNotEmpty() async {
        let pendingRequests = web3WalletClient.getPendingRequests(topic: "")
        XCTAssertEqual(1, pendingRequests.count)
    }
    
    func testSessionRequestRecordCalledAndNotNil() async {
        let sessionRequestRecord = web3WalletClient.getSessionRequestRecord(id: .left(""))
        XCTAssertNotNil(sessionRequestRecord)
    }
    
    func testAuthPendingRequestsCalledAndNotEmpty() async {
        let pendingRequests = try! web3WalletClient.getPendingRequests()
        XCTAssertEqual(1, pendingRequests.count)
    }
    
    func testCleanupCalled() async {
        try! await web3WalletClient.cleanup()
        XCTAssertTrue(signClient.cleanupCalled)
    }
    
    func testGetPairingsNotEmpty() async {
        XCTAssertEqual(1, web3WalletClient.getPairings().count)
    }
    
    func testEchoClientRegisterCalled() async {
        try! await echoClient.register(deviceToken: Data())
        XCTAssertTrue(echoClient.registedCalled)
        echoClient.registedCalled = false
        try! await echoClient.register(deviceToken: "")
        XCTAssertTrue(echoClient.registedCalled)
    }
}
