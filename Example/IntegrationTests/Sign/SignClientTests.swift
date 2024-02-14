import XCTest
import WalletConnectUtils
import JSONRPC
@testable import WalletConnectKMS
@testable import WalletConnectSign
@testable import WalletConnectRelay
import WalletConnectPairing
import WalletConnectNetworking
import Combine

final class SignClientTests: XCTestCase {
    var dapp: SignClient!
    var dappPairingClient: PairingClient!
    var wallet: SignClient!
    var walletPairingClient: PairingClient!
    private var publishers = Set<AnyCancellable>()


    static private func makeClients(name: String) -> (PairingClient, SignClient) {
        let logger = ConsoleLogger(prefix: name, loggingLevel: .debug)
        let keychain = KeychainStorageMock()
        let keyValueStorage = RuntimeKeyValueStorage()
        let relayClient = RelayClientFactory.create(
            relayHost: InputConfig.relayHost,
            projectId: InputConfig.projectId,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            socketFactory: DefaultSocketFactory(),
            networkMonitor: NetworkMonitor(),
            logger: logger
        )

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
            metadata: AppMetadata(name: name, description: "", url: "", icons: [""], redirect: AppMetadata.Redirect(native: "", universal: nil)),
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            pairingClient: pairingClient,
            networkingClient: networkingClient
        )

        let clientId = try! networkingClient.getClientId()
        logger.debug("My client id is: \(clientId)")
        
        return (pairingClient, client)
    }

    override func setUp() async throws {
        (dappPairingClient, dapp) = Self.makeClients(name: "🍏P")
        (walletPairingClient, wallet) = Self.makeClients(name: "🍎R")
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

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { _ in
            dappSettlementExpectation.fulfill()
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { _ in
            walletSettlementExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionReject() async throws {
        let sessionRejectExpectation = expectation(description: "Proposer is notified on session rejection")
        let requiredNamespaces = ProposalNamespace.stubRequired()

        class Store { var rejectedProposal: Session.Proposal? }
        let store = Store()
        let semaphore = DispatchSemaphore(value: 0)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.reject(proposalId: proposal.id, reason: .unsupportedChains)
                    store.rejectedProposal = proposal
                    semaphore.signal()
                } catch { XCTFail("\(error)") }
            }
        }.store(in: &publishers)
        dapp.sessionRejectionPublisher.sink { proposal, _ in
            semaphore.wait()
            XCTAssertEqual(store.rejectedProposal, proposal)
            sessionRejectExpectation.fulfill()
        }.store(in: &publishers)
        await fulfillment(of: [sessionRejectExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionDelete() async throws {
        let sessionDeleteExpectation = expectation(description: "Wallet expects session to be deleted")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do { try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                try await dapp.disconnect(topic: settledSession.topic)
            }
        }.store(in: &publishers)
        wallet.sessionDeletePublisher.sink { _ in
            sessionDeleteExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [sessionDeleteExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionPing() async throws {
        let expectation = expectation(description: "Proposer receives ping response")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                try! await self.wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }.store(in: &publishers)

        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                try! await dapp.ping(topic: settledSession.topic)
            }
        }.store(in: &publishers)

        dapp.pingResponsePublisher.sink { topic in
            let session = self.wallet.getSessions().first!
            XCTAssertEqual(topic, session.topic)
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)

        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)
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

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch {
                    XCTFail("\(error)")
                }
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                let request = try! Request(id: RPCID(0), topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain)
                try await dapp.request(params: request)
            }
        }.store(in: &publishers)
        wallet.sessionRequestPublisher.sink { [unowned self] (sessionRequest, _) in
            let receivedParams = try! sessionRequest.params.get([EthSendTransaction].self)
            XCTAssertEqual(receivedParams, requestParams)
            XCTAssertEqual(sessionRequest.method, requestMethod)
            requestExpectation.fulfill()
            Task(priority: .high) {
                try await wallet.respond(topic: sessionRequest.topic, requestId: sessionRequest.id, response: .response(AnyCodable(responseParams)))
            }
        }.store(in: &publishers)
        dapp.sessionResponsePublisher.sink { response in
            switch response.result {
            case .response(let response):
                XCTAssertEqual(try! response.get(String.self), responseParams)
            case .error:
                XCTFail()
            }
            responseExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [requestExpectation, responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionRequestFailureResponse() async throws {
        let expectation = expectation(description: "Dapp expects to receive an error response")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        let requestMethod = "eth_sendTransaction"
        let requestParams = [EthSendTransaction.stub()]
        let error = JSONRPCError(code: 0, message: "error")

        let chain = Blockchain("eip155:1")!

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                let request = try! Request(id: RPCID(0), topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain)
                try await dapp.request(params: request)
            }
        }.store(in: &publishers)
        wallet.sessionRequestPublisher.sink { [unowned self] (sessionRequest, _) in
            Task(priority: .high) {
                try await wallet.respond(topic: sessionRequest.topic, requestId: sessionRequest.id, response: .error(error))
            }
        }.store(in: &publishers)
        dapp.sessionResponsePublisher.sink { response in
            switch response.result {
            case .response:
                XCTFail()
            case .error(let receivedError):
                XCTAssertEqual(error, receivedError)
            }
            expectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testNewSessionOnExistingPairing() async throws {
        let dappSettlementExpectation = expectation(description: "Dapp settles session")
        dappSettlementExpectation.expectedFulfillmentCount = 2
        let walletSettlementExpectation = expectation(description: "Wallet settles session")
        walletSettlementExpectation.expectedFulfillmentCount = 2
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        var initiatedSecondSession = false

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { [unowned self] _ in
            dappSettlementExpectation.fulfill()
            let pairingTopic = dappPairingClient.getPairings().first!.topic
            if !initiatedSecondSession {
                Task(priority: .high) {
                    _ = try! await dapp.connect(requiredNamespaces: requiredNamespaces, topic: pairingTopic)
                }
                initiatedSecondSession = true
            }
        }.store(in: &publishers)
        wallet.sessionSettlePublisher.sink { _ in
            walletSettlementExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSuccessfulSessionUpdateNamespaces() async throws {
        let expectation = expectation(description: "Dapp updates namespaces")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.update(topic: settledSession.topic, namespaces: sessionNamespaces)
            }
        }.store(in: &publishers)
        dapp.sessionUpdatePublisher.sink { _, _ in
            expectation.fulfill()
        }.store(in: &publishers)
        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testSuccessfulSessionExtend() async throws {
        let expectation = expectation(description: "Dapp extends session")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }.store(in: &publishers)

        dapp.sessionExtendPublisher.sink { _, _ in
            expectation.fulfill()
        }.store(in: &publishers)

        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.extend(topic: settledSession.topic)
            }
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)

        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionEventSucceeds() async throws {
        let expectation = expectation(description: "Dapp receives session event")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        let event = Session.Event(name: "any", data: AnyCodable("event_data"))
        let chain = Blockchain("eip155:1")!

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }.store(in: &publishers)

        dapp.sessionEventPublisher.sink { _, _, _ in
            expectation.fulfill()
        }.store(in: &publishers)

        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                try! await wallet.emit(topic: settledSession.topic, event: event, chainId: chain)
            }
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)

        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionEventFails() async throws {
        let expectation = expectation(description: "Dapp receives session event")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        let event = Session.Event(name: "unknown", data: AnyCodable("event_data"))
        let chain = Blockchain("eip155:1")!

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            }
        }.store(in: &publishers)

        dapp.sessionSettlePublisher.sink { [unowned self] settledSession in
            Task(priority: .high) {
                await XCTAssertThrowsErrorAsync(try await wallet.emit(topic: settledSession.topic, event: event, chainId: chain))
                expectation.fulfill()
            }
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)

        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)
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
                chains: [Blockchain("eip155:137")!, Blockchain("eip155:1")!],
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
        
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata.stub(),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil))), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        let sessionNamespaces = try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [
                Blockchain("eip155:137")!,
                Blockchain("eip155:1")!,
                Blockchain("eip155:5")!,
                Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!
            ],
            methods: ["personal_sign", "eth_sendTransaction", "solana_signMessage"],
            events: ["any"],
            accounts: [
                Account(blockchain: Blockchain("solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!, address: "4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ")!,
                Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!,
                Account(blockchain: Blockchain("eip155:137")!, address: "0x00")!,
                Account(blockchain: Blockchain("eip155:5")!, address: "0x00")!
            ]
        )
        
        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { settledSession in
            dappSettlementExpectation.fulfill()
        }.store(in: &publishers)
        wallet.sessionSettlePublisher.sink { _ in
            walletSettlementExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
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
        
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil)),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil))), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        let sessionNamespaces = try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [
                Blockchain("eip155:137")!,
                Blockchain("eip155:1")!
            ],
            methods: ["personal_sign", "eth_sendTransaction"],
            events: ["any"],
            accounts: [
                Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!,
                Account(blockchain: Blockchain("eip155:137")!, address: "0x00")!
            ]
        )
        
        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { [unowned self] _ in
            dappSettlementExpectation.fulfill()
        }.store(in: &publishers)
        wallet.sessionSettlePublisher.sink { _ in
            walletSettlementExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
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
        
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil)),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil))), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        let sessionNamespaces = try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [
                Blockchain("eip155:1")!,
                Blockchain("eip155:5")!
            ],
            methods: ["personal_sign", "eth_sendTransaction"],
            events: ["any"],
            accounts: [
                Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!,
                Account(blockchain: Blockchain("eip155:5")!, address: "0x00")!
            ]
        )
        
        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }.store(in: &publishers)
        dapp.sessionSettlePublisher.sink { _ in
            dappSettlementExpectation.fulfill()
        }.store(in: &publishers)
        wallet.sessionSettlePublisher.sink { _ in
            walletSettlementExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
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
        
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil)),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil))), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        do {
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [
                    Blockchain("eip155:1")!
                ],
                methods: ["personal_sign", "eth_sendTransaction"],
                events: ["any"],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!
                ]
            )
            
            wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
                Task(priority: .high) {
                    do {
                        try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                    } catch {
                        settlementFailedExpectation.fulfill()
                    }
                }
            }.store(in: &publishers)
        } catch {
            settlementFailedExpectation.fulfill()
        }
        
        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [settlementFailedExpectation], timeout: InputConfig.defaultTimeout)
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
        
        let sessionProposal = Session.Proposal(
            id: "",
            pairingTopic: "",
            proposer: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil)),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata(name: "", description: "", url: "", icons: [], redirect: AppMetadata.Redirect(native: "", universal: nil))), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        do {
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [
                    Blockchain("eip155:1")!,
                    Blockchain("eip155:137")!
                ],
                methods: ["personal_sign"],
                events: ["any"],
                accounts: [
                    Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!,
                    Account(blockchain: Blockchain("eip155:137")!, address: "0x00")!
                ]
            )
            
            wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
                Task(priority: .high) {
                    do {
                        try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                    } catch {
                        settlementFailedExpectation.fulfill()
                    }
                }
            }.store(in: &publishers)
        } catch {
            settlementFailedExpectation.fulfill()
        }

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [settlementFailedExpectation], timeout: 1)
    }
}
