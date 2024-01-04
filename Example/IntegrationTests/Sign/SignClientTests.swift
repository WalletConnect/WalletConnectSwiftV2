import XCTest
import WalletConnectUtils
import JSONRPC
@testable import WalletConnectKMS
@testable import WalletConnectSign
@testable import WalletConnectRelay
@testable import WalletConnectUtils
import WalletConnectPairing
import WalletConnectNetworking
import Combine

final class SignClientTests: XCTestCase {
    var dapp: SignClient!
    var dappPairingClient: PairingClient!
    var wallet: SignClient!
    var walletPairingClient: PairingClient!
    private var publishers = Set<AnyCancellable>()
    let walletAccount = Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!
    let prvKey = Data(hex: "462c1dad6832d7d96ccf87bd6a686a4110e114aaaebd5512e552c0e3a87b480f")
    let eip1271Signature = "0xc1505719b2504095116db01baaf276361efd3a73c28cf8cc28dabefa945b8d536011289ac0a3b048600c1e692ff173ca944246cf7ceb319ac2262d27b395c82b1c"

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
            networkingClient: networkingClient,
            iatProvider: IATProviderMock(),
            projectId: InputConfig.projectId,
            crypto: DefaultCryptoProvider()
        )

        let clientId = try! networkingClient.getClientId()
        logger.debug("My client id is: \(clientId)")
        
        return (pairingClient, client)
    }

    override func setUp() async throws {
        (dappPairingClient, dapp) = Self.makeClients(name: "🍏Dapp")
        (walletPairingClient, wallet) = Self.makeClients(name: "🍎Wallet")
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
        wallet.sessionSettlePublisher.sink { _ in
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

        let uri = try! await dappPairingClient.create()
        try await dapp.connect(requiredNamespaces: requiredNamespaces, topic: uri.topic)
        try await walletPairingClient.pair(uri: uri)

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.rejectSession(proposalId: proposal.id, reason: .userRejectedChains) // TODO: Review reason
                    store.rejectedProposal = proposal
                } catch { XCTFail("\(error)") }
            }
        }.store(in: &publishers)
        dapp.sessionRejectionPublisher.sink { proposal, _ in
            XCTAssertEqual(store.rejectedProposal, proposal)
            sessionRejectExpectation.fulfill() // TODO: Assert reason code
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
                let request = Request(id: RPCID(0), topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain, expiry: nil)
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
                let request = Request(id: RPCID(0), topic: settledSession.topic, method: requestMethod, params: requestParams, chainId: chain, expiry: nil)
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
        await fulfillment(of: [settlementFailedExpectation], timeout: 1)
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


    func testEIP191SessionAuthenticated() async throws {
        let responseExpectation = expectation(description: "successful response delivered")

        wallet.authRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let siweMessage = try wallet.formatAuthMessage(payload: request.payload, account: walletAccount)

                let signature = try signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.makeAuthObject(authRequest: request, signature: signature, account: walletAccount)

                try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [auth])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)


        let uri = try await dapp.authenticate(RequestParams.stub())
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testEIP191SessionAuthenticatedMultiCacao() async throws {
        let responseExpectation = expectation(description: "successful response delivered")

        wallet.authRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                var cacaos = [Cacao]()

                request.payload.chains.forEach { chain in

                    let account = Account(blockchain: Blockchain(chain)!, address: walletAccount.address)!
                    let siweMessage = try! wallet.formatAuthMessage(payload: request.payload, account: account)

                    let signature = try! signer.sign(
                        message: siweMessage,
                        privateKey: prvKey,
                        type: .eip191)

                    let cacao = try! wallet.makeAuthObject(authRequest: request, signature: signature, account: account)
                    cacaos.append(cacao)

                }
                try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: cacaos)
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .success(let session) = result else { XCTFail(); return }
            XCTAssertEqual(session.accounts.count, 2)
            XCTAssertEqual(session.namespaces["eip155"]?.methods.count, 2)
            XCTAssertEqual(session.namespaces["eip155"]?.accounts.count, 2)
            responseExpectation.fulfill()
        }
        .store(in: &publishers)


        let uri = try await dapp.authenticate(RequestParams.stub(chains: ["eip155:1", "eip155:137"]))
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

//    func testEIP1271SessionAuthenticated() async throws {
//
//        let account = Account(chainIdentifier: "eip155:1", address: "0x2faf83c542b68f1b4cdc0e770e8cb9f567b08f71")!
//
//        let responseExpectation = expectation(description: "successful response delivered")
//        let uri = try! await dappPairingClient.create()
//        try! await dapp.authenticate(RequestParams(
//            domain: "localhost",
//            chains: ["eip155:1"],
//            nonce: "1665443015700",
//            aud: "http://localhost:3000/",
//            nbf: nil,
//            exp: "2022-10-11T23:03:35.700Z",
//            statement: nil,
//            requestId: nil,
//            resources: nil
//        ), topic: uri.topic)
//
//        try await walletPairingClient.pair(uri: uri)
//
//        wallet.authRequestPublisher.sink { [unowned self] request in
//            Task(priority: .high) {
//                let signature = CacaoSignature(t: .eip1271, s: eip1271Signature)
//                try! await wallet.approveSessionAuthenticate(requestId: request.0.id, signature: signature, account: account)
//            }
//        }
//        .store(in: &publishers)
//        dapp.authResponsePublisher.sink { (_, result) in
//            guard case .success = result else { XCTFail(); return }
//            responseExpectation.fulfill()
//        }
//        .store(in: &publishers)
//        wait(for: [responseExpectation], timeout: InputConfig.defaultTimeout)
//    }

    func testEIP191SessionAuthenticateSignatureVerificationFailed() async {
        let responseExpectation = expectation(description: "error response delivered")
        let uri = try! await dapp.authenticate(RequestParams.stub())
        try! await dapp.authenticate(RequestParams.stub(), topic: uri.topic)

        try? await walletPairingClient.pair(uri: uri)
        wallet.authRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let invalidSignature = CacaoSignature(t: .eip1271, s: eip1271Signature)

                let auth = try wallet.makeAuthObject(authRequest: request, signature: invalidSignature, account: walletAccount)

                try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [auth])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case let .failure(error) = result,
                  error == .signatureVerificationFailed else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionAuthenticateUserRespondError() async {
        let responseExpectation = expectation(description: "error response delivered")
        let uri = try! await dapp.authenticate(RequestParams.stub())

        try! await dapp.authenticate(RequestParams.stub(), topic: uri.topic)

        try? await walletPairingClient.pair(uri: uri)
        wallet.authRequestPublisher.sink { [unowned self] request in
            Task(priority: .high) {
                try! await wallet.rejectSession(requestId: request.0.id)
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .failure(let error) = result else { XCTFail(); return }
            XCTAssertEqual(error, .userRejeted)
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionRequestOnAuthenticatedSession() async throws {
        let requestExpectation = expectation(description: "Wallet expects to receive a request")
        let responseExpectation = expectation(description: "Dapp expects to receive a response")
        
        let requestMethod = "eth_sendTransaction"
        let requestParams = [EthSendTransaction.stub()]
        let responseParams = "0xdeadbeef"
        let chain = Blockchain("eip155:1")!

        wallet.authRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let Siwemessage = try wallet.formatAuthMessage(payload: request.payload, account: walletAccount)

                let signature = try signer.sign(
                    message: Siwemessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.makeAuthObject(authRequest: request, signature: signature, account: walletAccount)

                try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [auth])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { [unowned self] (_, result) in
            guard case .success(let session) = result else { XCTFail(); return }

            Task(priority: .high) {
                let request = Request(id: RPCID(0), topic: session.topic, method: requestMethod, params: requestParams, chainId: chain, expiry: nil)
                try await dapp.request(params: request)
            }
        }
        .store(in: &publishers)

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


        let uri = try await dapp.authenticate(RequestParams.stub())

        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [requestExpectation, responseExpectation], timeout: InputConfig.defaultTimeout)
    }

}
