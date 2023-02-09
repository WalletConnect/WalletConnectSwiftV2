import XCTest
import WalletConnectUtils
import JSONRPC
@testable import WalletConnectKMS
@testable import WalletConnectSign
@testable import WalletConnectRelay
import WalletConnectPairing
import WalletConnectNetworking

final class SignClientTests: XCTestCase {
    var dapp: ClientDelegate!
    var wallet: ClientDelegate!

    static private func makeClientDelegate(name: String) -> ClientDelegate {
        let logger = ConsoleLogger(suffix: name, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let relayClient = RelayClient(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: RuntimeKeyValueStorage(),
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            socketConnectionType: .automatic,
            logger: logger
        )
        let keyValueStorage = RuntimeKeyValueStorage()

        let networkingClient = NetworkingClientFactory.create(
            relayClient: relayClient,
            logger: logger,
            keychainStorage: keychain,
            keyValueStorage: keyValueStorage
        )
        let pairingClient = PairingClientFactory.create(
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            networkingClient: networkingClient
        )
        let client = SignClientFactory.create(
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""]),
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            pairingClient: pairingClient,
            networkingClient: networkingClient
        )
        return ClientDelegate(client: client)
    }

    override func setUp() async throws {
        dapp = Self.makeClientDelegate(name: "🍏P")
        wallet = Self.makeClientDelegate(name: "🍎R")
    }

    override func tearDown() {
        dapp = nil
        wallet = nil
    }

    func testSessionPropose() async throws {
        let dappSettlementExpectation = expectation(description: "Dapp expects to settle a session")
        let walletSettlementExpectation = expectation(description: "Wallet expects to settle a session")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { _ in
            dappSettlementExpectation.fulfill()
        }
        wallet.onSessionSettled = { _ in
            walletSettlementExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionReject() async throws {
        let sessionRejectExpectation = expectation(description: "Proposer is notified on session rejection")

        class Store { var rejectedProposal: Session.Proposal? }
        let store = Store()

        let uri = try await dapp.client.connect(requiredNamespaces: ProposalNamespace.stubRequired())
        try await wallet.client.pair(uri: uri!)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.reject(proposalId: proposal.id, reason: .userRejectedChains) // TODO: Review reason
                    store.rejectedProposal = proposal
                } catch { XCTFail("\(error)") }
            }
        }
        dapp.onSessionRejected = { proposal, _ in
            XCTAssertEqual(store.rejectedProposal, proposal)
            sessionRejectExpectation.fulfill() // TODO: Assert reason code
        }
        wait(for: [sessionRejectExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionDelete() async throws {
        let sessionDeleteExpectation = expectation(description: "Wallet expects session to be deleted")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do { try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try await dapp.client.disconnect(topic: settledSession.topic)
            }
        }
        wallet.onSessionDelete = {
            sessionDeleteExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [sessionDeleteExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionPing() async throws {
        let expectation = expectation(description: "Proposer receives ping response")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { proposal in
            Task(priority: .high) {
                try! await self.wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }

        dapp.onSessionSettled = { sessionSettled in
            Task(priority: .high) {
                try! await self.dapp.client.ping(topic: sessionSettled.topic)
            }
        }

        dapp.onPing = { topic in
            let session = self.wallet.client.getSessions().first!
            XCTAssertEqual(topic, session.topic)
            expectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)!
        try await wallet.client.pair(uri: uri)

        wait(for: [expectation], timeout: .infinity)
    }

    func testSessionRequest() async throws {
        let requestExpectation = expectation(description: "Wallet expects to receive a request")
        let responseExpectation = expectation(description: "Dapp expects to receive a response")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        let requestMethod = "eth_sendTransaction"
        let requestParams = [EthSendTransaction.stub()]
        let responseParams = "0xdeadbeef"
        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                let request = Request(id: RPCID(0), topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain, expiry: nil)
                try await dapp.client.request(params: request)
            }
        }
        wallet.onSessionRequest = { [unowned self] sessionRequest in
            let receivedParams = try! sessionRequest.params.get([EthSendTransaction].self)
            XCTAssertEqual(receivedParams, requestParams)
            XCTAssertEqual(sessionRequest.method, requestMethod)
            requestExpectation.fulfill()
            Task(priority: .high) {
                try await wallet.client.respond(topic: sessionRequest.topic, requestId: sessionRequest.id, response: .response(AnyCodable(responseParams)))
            }
        }
        dapp.onSessionResponse = { response in
            switch response.result {
            case .response(let response):
                XCTAssertEqual(try! response.get(String.self), responseParams)
            case .error:
                XCTFail()
            }
            responseExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [requestExpectation, responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionRequestFailureResponse() async throws {
        let expectation = expectation(description: "Dapp expects to receive an error response")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        let requestMethod = "eth_sendTransaction"
        let requestParams = [EthSendTransaction.stub()]
        let error = JSONRPCError(code: 0, message: "error")

        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                let request = Request(id: RPCID(0), topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain, expiry: nil)
                try await dapp.client.request(params: request)
            }
        }
        wallet.onSessionRequest = { [unowned self] sessionRequest in
            Task(priority: .high) {
                try await wallet.client.respond(topic: sessionRequest.topic, requestId: sessionRequest.id, response: .error(error))
            }
        }
        dapp.onSessionResponse = { response in
            switch response.result {
            case .response:
                XCTFail()
            case .error(let receivedError):
                XCTAssertEqual(error, receivedError)
            }
            expectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testNewSessionOnExistingPairing() async {
        let dappSettlementExpectation = expectation(description: "Dapp settles session")
        dappSettlementExpectation.expectedFulfillmentCount = 2
        let walletSettlementExpectation = expectation(description: "Wallet settles session")
        walletSettlementExpectation.expectedFulfillmentCount = 2
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        var initiatedSecondSession = false

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { [unowned self] _ in
            dappSettlementExpectation.fulfill()
            let pairingTopic = dapp.client.getPairings().first!.topic
            if !initiatedSecondSession {
                Task(priority: .high) {
                    _ = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces, topic: pairingTopic)
                }
                initiatedSecondSession = true
            }
        }
        wallet.onSessionSettled = { _ in
            walletSettlementExpectation.fulfill()
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)
        wait(for: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSuccessfulSessionUpdateNamespaces() async {
        let expectation = expectation(description: "Dapp updates namespaces")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }
        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.client.update(topic: settledSession.topic, namespaces: sessionNamespaces)
            }
        }
        dapp.onSessionUpdateNamespaces = { _, _ in
            expectation.fulfill()
        }
        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)
        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testSuccessfulSessionExtend() async {
        let expectation = expectation(description: "Dapp extends session")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }

        dapp.onSessionExtend = { _, _ in
            expectation.fulfill()
        }

        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.client.extend(topic: settledSession.topic)
            }
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionEventSucceeds() async {
        let expectation = expectation(description: "Dapp receives session event")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        let event = Session.Event(name: "any", data: AnyCodable("event_data"))
        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }

        dapp.onEventReceived = { _, _ in
            expectation.fulfill()
        }

        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.client.emit(topic: settledSession.topic, event: event, chainId: chain)
            }
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionEventFails() async {
        let expectation = expectation(description: "Dapp receives session event")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        let event = Session.Event(name: "unknown", data: AnyCodable("event_data"))
        let chain = Blockchain("eip155:1")!

        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }

        dapp.onSessionSettled = { [unowned self] settledSession in
            Task(priority: .high) {
                await XCTAssertThrowsErrorAsync(try await wallet.client.emit(topic: settledSession.topic, event: event, chainId: chain))
                expectation.fulfill()
            }
        }

        let uri = try! await dapp.client.connect(requiredNamespaces: requiredNamespaces)
        try! await wallet.client.pair(uri: uri!)

        wait(for: [expectation], timeout: InputConfig.defaultTimeout)
    }
    
    func testCaip25SatisfyAllRequiredAllOptionalNamespacesSuccessful() async throws {
        let dappSettlementExpectation = expectation(description: "Dapp expects to settle a session")
        let walletSettlementExpectation = expectation(description: "Wallet expects to settle a session")
        
        let requiredNamespaces: [String: ProposalNamespace] = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:137")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let optionalNamespaces: [String: ProposalNamespace] = [
            "eip155:5": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "solana": ProposalNamespace(
                chains: [Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!],
                methods: ["solana_signMessage"],
                events: ["any"]
            )
        ]
        
        let sessionNamespaces: [String: SessionNamespace] = [
            "eip155:1": SessionNamespace(
                accounts: [Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:137")!],
                accounts: [Account(blockchain: Blockchain("eip155:137")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155:5": SessionNamespace(
                accounts: [Account(blockchain: Blockchain("eip155:5")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "solana": SessionNamespace(
                chains: [Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!],
                accounts: [Account(blockchain: Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!, address: "0x00")!],
                methods: ["solana_signMessage"],
                events: ["any"]
            )
        ]
        
        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { _ in
            dappSettlementExpectation.fulfill()
        }
        wallet.onSessionSettled = { _ in
            walletSettlementExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }
    
    func testCaip25SatisfyAllRequiredNamespacesSuccessful() async throws {
        let dappSettlementExpectation = expectation(description: "Dapp expects to settle a session")
        let walletSettlementExpectation = expectation(description: "Wallet expects to settle a session")
        
        let requiredNamespaces: [String: ProposalNamespace] = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:137")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let optionalNamespaces: [String: ProposalNamespace] = [
            "eip155:5": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let sessionNamespaces: [String: SessionNamespace] = [
            "eip155:1": SessionNamespace(
                accounts: [Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:137")!],
                accounts: [Account(blockchain: Blockchain("eip155:137")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
        ]
        
        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { _ in
            dappSettlementExpectation.fulfill()
        }
        wallet.onSessionSettled = { _ in
            walletSettlementExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }
    
    func testCaip25SatisfyEmptyRequiredNamespacesExtraOptionalNamespacesSuccessful() async throws {
        let dappSettlementExpectation = expectation(description: "Dapp expects to settle a session")
        let walletSettlementExpectation = expectation(description: "Wallet expects to settle a session")
        
        let requiredNamespaces: [String: ProposalNamespace] = [:]
        
        let optionalNamespaces: [String: ProposalNamespace] = [
            "eip155:5": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let sessionNamespaces: [String: SessionNamespace] = [
            "eip155:5": SessionNamespace(
                accounts: [Account(blockchain: Blockchain("eip155:5")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155:1": SessionNamespace(
                accounts: [Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
        dapp.onSessionSettled = { _ in
            dappSettlementExpectation.fulfill()
        }
        wallet.onSessionSettled = { _ in
            walletSettlementExpectation.fulfill()
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }
    
    func testCaip25SatisfyPartiallyRequiredNamespacesFails() async throws {
        let settlementFailedExpectation = expectation(description: "Dapp fails to settle a session")
        
        let requiredNamespaces: [String: ProposalNamespace] = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155:137": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let optionalNamespaces: [String: ProposalNamespace] = [
            "eip155:5": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let sessionNamespaces: [String: SessionNamespace] = [
            "eip155:1": SessionNamespace(
                accounts: [Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
        ]
        
        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    settlementFailedExpectation.fulfill()
                }
            }
        }
        
        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [settlementFailedExpectation], timeout: 1)
    }
    
    func testCaip25SatisfyPartiallyRequiredNamespacesMethodsFails() async throws {
        let settlementFailedExpectation = expectation(description: "Dapp fails to settle a session")
        
        let requiredNamespaces: [String: ProposalNamespace] = [
            "eip155:1": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
            "eip155": ProposalNamespace(
                chains: [Blockchain("eip155:137")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let optionalNamespaces: [String: ProposalNamespace] = [
            "eip155:5": ProposalNamespace(
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            )
        ]
        
        let sessionNamespaces: [String: SessionNamespace] = [
            "eip155:1": SessionNamespace(
                accounts: [Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!],
                methods: ["personal_sign"],
                events: ["any"]
            ),
            "eip155": SessionNamespace(
                chains: [Blockchain("eip155:137")!],
                accounts: [Account(blockchain: Blockchain("eip155:137")!, address: "0x00")!],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"]
            ),
        ]
        
        wallet.onSessionProposal = { [unowned self] proposal in
            Task(priority: .high) {
                do {
                    try await wallet.client.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    settlementFailedExpectation.fulfill()
                }
            }
        }

        let uri = try await dapp.client.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)
        try await wallet.client.pair(uri: uri!)
        wait(for: [settlementFailedExpectation], timeout: InputConfig.defaultTimeout)
    }
}
