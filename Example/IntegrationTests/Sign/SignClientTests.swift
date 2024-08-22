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
    var dappKeyValueStorage: RuntimeKeyValueStorage!
    var dappRelayClient: RelayClient!
    var walletRelayClient: RelayClient!
    private var publishers = Set<AnyCancellable>()
    let walletAccount = Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!
    let prvKey = Data(hex: "462c1dad6832d7d96ccf87bd6a686a4110e114aaaebd5512e552c0e3a87b480f")
    let eip1271Signature = "0xdeaddeaddead4095116db01baaf276361efd3a73c28cf8cc28dabefa945b8d536011289ac0a3b048600c1e692ff173ca944246cf7ceb319ac2262d27b395c82b1c"
    let walletLinkModeUniversalLink = "https://test"


    static private func makeClients(name: String, linkModeUniversalLink: String? = "https://x.com", supportLinkMode: Bool = false) -> (PairingClient, SignClient, RuntimeKeyValueStorage, RelayClient) {
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
            networkingClient: networkingClient,
            eventsClient: MockEventsClient()
        )
        let metadata = AppMetadata(name: name, description: "", url: "", icons: [""], redirect: try! AppMetadata.Redirect(native: "", universal: linkModeUniversalLink, linkMode: supportLinkMode))

        let client = SignClientFactory.create(
            metadata: metadata,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychain,
            pairingClient: pairingClient,
            networkingClient: networkingClient,
            iatProvider: IATProviderMock(),
            projectId: InputConfig.projectId,
            crypto: DefaultCryptoProvider(),
            eventsClient: MockEventsClient()
        )

        let clientId = try! networkingClient.getClientId()
        logger.debug("My client id is: \(clientId)")
        
        return (pairingClient, client, keyValueStorage, relayClient)
    }

    override func setUp() async throws {
        (dappPairingClient, dapp, dappKeyValueStorage, dappRelayClient) = Self.makeClients(name: "🍏Dapp")
        (walletPairingClient, wallet, _, walletRelayClient) = Self.makeClients(name: "🍎Wallet", linkModeUniversalLink: walletLinkModeUniversalLink)
    }

    func setUpDappForLinkMode() async throws {
        try await tearDown()
        (dappPairingClient, dapp, dappKeyValueStorage, dappRelayClient) = Self.makeClients(name: "🍏Dapp", supportLinkMode: true)
        (walletPairingClient, wallet, _, walletRelayClient) = Self.makeClients(name: "🍎Wallet", linkModeUniversalLink: walletLinkModeUniversalLink, supportLinkMode: true)
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
                    _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [dappSettlementExpectation, walletSettlementExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionReject() async throws {
        let sessionRejectExpectation = expectation(description: "Proposer is notified on session rejection")
        let requiredNamespaces = ProposalNamespace.stubRequired()

        class Store { var rejectedProposal: Session.Proposal? }
        let store = Store()
        let semaphore = DispatchSemaphore(value: 0)

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)
        try await walletPairingClient.pair(uri: uri)

        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    try await wallet.rejectSession(proposalId: proposal.id, reason: .unsupportedChains)
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
                do { _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)

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
        
        // sleep is needed as emitRequestIfPending() will be called on client init and then on request itself, second request would be debouced
        sleep(1)
        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch {
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)

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

        // sleep is needed as emitRequestIfPending() will be called on client init and then on request itself, second request would be debouced
        sleep(1)
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)

        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [expectation], timeout: InputConfig.defaultTimeout)
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
                let updateNamespace = SessionNamespace.make(
                    toRespond: ProposalNamespace.stubRequired(chains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!])
                )
                try! await wallet.update(topic: settledSession.topic, namespaces: updateNamespace)
            }
        }.store(in: &publishers)
        dapp.sessionUpdatePublisher.sink { _, namespace in
            XCTAssertEqual(namespace.values.first?.accounts.count, 2)
            expectation.fulfill()
        }.store(in: &publishers)
        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)

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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)

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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)

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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces)

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
                chains: [Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!],
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
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata.stub()), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
        )
        
        let sessionNamespaces = try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: [
                Blockchain("eip155:137")!,
                Blockchain("eip155:1")!,
                Blockchain("eip155:5")!,
                Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!
            ],
            methods: ["personal_sign", "eth_sendTransaction", "solana_signMessage"],
            events: ["any"],
            accounts: [
                Account(blockchain: Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!, address: "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!,
                Account(blockchain: Blockchain("eip155:1")!, address: "0x00")!,
                Account(blockchain: Blockchain("eip155:137")!, address: "0x00")!,
                Account(blockchain: Blockchain("eip155:5")!, address: "0x00")!
            ]
        )
        
        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do {
                    _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)
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
            proposer: AppMetadata.stub(),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata.stub()), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
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
                    _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

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
            proposer: AppMetadata.stub(),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata.stub()), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
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
                    _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
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

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

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
            proposer: AppMetadata.stub(),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata.stub()), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
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
                        _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                    } catch {
                        settlementFailedExpectation.fulfill()
                    }
                }
            }.store(in: &publishers)
        } catch {
            settlementFailedExpectation.fulfill()
        }
        
        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

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
            proposer: AppMetadata.stub(),
            requiredNamespaces: requiredNamespaces,
            optionalNamespaces: optionalNamespaces,
            sessionProperties: nil,
            proposal: SessionProposal(relays: [], proposer: Participant(publicKey: "", metadata: AppMetadata.stub()), requiredNamespaces: [:], optionalNamespaces: [:], sessionProperties: [:])
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
                        _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
                    } catch {
                        settlementFailedExpectation.fulfill()
                    }
                }
            }.store(in: &publishers)
        } catch {
            settlementFailedExpectation.fulfill()
        }

        let uri = try! await dapp.connect(requiredNamespaces: requiredNamespaces, optionalNamespaces: optionalNamespaces)

        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [settlementFailedExpectation], timeout: 1)
    }


    func testEIP191SessionAuthenticated() async throws {
        let responseExpectation = expectation(description: "successful response delivered")

        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: walletAccount)

                let signature = try signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                _ = try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [auth])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)


        let uri = try await dapp.authenticate(AuthRequestParams.stub())!
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testEIP191SessionAuthenticateEmptyMethods() async throws {
        let responseExpectation = expectation(description: "successful response delivered")

        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: walletAccount)

                let signature = try signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                _ = try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [auth])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)


        let uri = try await dapp.authenticate(AuthRequestParams.stub(methods: nil))!
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testEIP191SessionAuthenticatedMultiCacao() async throws {
        let responseExpectation = expectation(description: "successful response delivered")

        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                var cacaos = [Cacao]()

                request.payload.chains.forEach { chain in

                    let account = Account(blockchain: Blockchain(chain)!, address: walletAccount.address)!

                    let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_sendTransaction", "personal_sign"])

                    let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: account)

                    let signature = try! signer.sign(
                        message: siweMessage,
                        privateKey: prvKey,
                        type: .eip191)

                    let cacao = try! wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: account)
                    cacaos.append(cacao)

                }
                _ = try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: cacaos)
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .success(let (session, _)) = result,
                let session = session else { XCTFail(); return }
            XCTAssertEqual(session.accounts.count, 2)
            XCTAssertEqual(session.namespaces["eip155"]?.methods.count, 2)
            XCTAssertEqual(session.namespaces["eip155"]?.accounts.count, 2)
            responseExpectation.fulfill()
        }
        .store(in: &publishers)


        let uri = try await dapp.authenticate(AuthRequestParams.stub(chains: ["eip155:1", "eip155:137"]))!
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testEIP1271SessionAuthenticated() async throws {

        let account = Account(chainIdentifier: "eip155:1", address: "0x6DF3d14554742D67068BB7294C80107a3c655A56")!
        let eip1271Signature = "0xb518b65724f224f8b12dedeeb06f8b278eb7d3b42524959bed5d0dfa49801bd776c7ee05de396eadc38ee693c917a04d93b20981d68c4a950cbc42ea7f4264bc1c"

        let responseExpectation = expectation(description: "successful response delivered")
        let uri = try! await dapp.authenticate(AuthRequestParams(
            domain: "etherscan.io",
            chains: ["eip155:1"],
            nonce: "DTYxeNr95Ne7Sape5",
            uri: "https://etherscan.io/verifiedSignatures#",
            nbf: nil,
            exp: nil,
            statement: "Sign message to verify ownership of the address 0x6DF3d14554742D67068BB7294C80107a3c655A56 on etherscan.io",
            requestId: nil,
            resources: nil,
            methods: nil
        ))!

        try await walletPairingClient.pair(uri: uri)

        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signature = CacaoSignature(t: .eip1271, s: eip1271Signature)
                let cacao = try! wallet.buildSignedAuthObject(authPayload: request.payload, signature: signature, account: account)
                _ = try await wallet.approveSessionAuthenticate(requestId: request.id, auths: [cacao])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testEIP191SessionAuthenticateSignatureVerificationFailed() async {
        let requestExpectation = expectation(description: "error response delivered")
        let uri = try! await dapp.authenticate(AuthRequestParams.stub())!

        try? await walletPairingClient.pair(uri: uri)
        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let invalidSignature = CacaoSignature(t: .eip1271, s: eip1271Signature)


                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

                let cacao = try! wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: invalidSignature, account: walletAccount)

                await XCTAssertThrowsErrorAsync(try await wallet.approveSessionAuthenticate(requestId: request.id, auths: [cacao]))
                requestExpectation.fulfill()
            }
        }
        .store(in: &publishers)
        await fulfillment(of: [requestExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testSessionAuthenticateUserRespondError() async {
        let responseExpectation = expectation(description: "error response delivered")
        let uri = try! await dapp.authenticate(AuthRequestParams.stub())!

        try? await walletPairingClient.pair(uri: uri)
        wallet.authenticateRequestPublisher.sink { [unowned self] request in
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
        // sleep is needed as emitRequestIfPending() will be called on client init and then on request itself, second request would be debouced
        sleep(1)
        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_sendTransaction", "personal_sign"])

                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: walletAccount)

                let signature = try! signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let cacao = try! wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                _ = try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [cacao])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { [unowned self] (_, result) in
            guard case .success(let (session, _)) = result,
                let session = session else { XCTFail(); return }
            Task(priority: .high) {
                let request = try Request(id: RPCID(0), topic: session.topic, method: requestMethod, params: requestParams, chainId: Blockchain("eip155:1")!)
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


        let uri = try await dapp.authenticate(AuthRequestParams.stub())!

        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [requestExpectation, responseExpectation], timeout: InputConfig.defaultTimeout)
    }


    func testSessionRequestOnAuthenticatedSessionForAChainNotIncludedInCacao() async throws {
        let requestExpectation = expectation(description: "Wallet expects to receive a request")
        let responseExpectation = expectation(description: "Dapp expects to receive a response")

        let requestMethod = "eth_sendTransaction"
        let requestParams = [EthSendTransaction.stub()]
        let responseParams = "0xdeadbeef"
        let chain = Blockchain("eip155:1")!
        // sleep is needed as emitRequestIfPending() will be called on client init and then on request itself, second request would be debouced
        sleep(1)
        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_sendTransaction", "personal_sign"])

                let signingAccount = Account(chainIdentifier: "eip155:1", address: "0x724d0D2DaD3fbB0C168f947B87Fa5DBe36F1A8bf")!
                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: signingAccount)

                let signature = try! signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let cacao = try! wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                _ = try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [cacao])
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { [unowned self] (_, result) in
            guard case .success(let (session, _)) = result,
                let session = session else { XCTFail(); return }
            Task(priority: .high) {
                let request = try Request(id: RPCID(0), topic: session.topic, method: requestMethod, params: requestParams, chainId: Blockchain("eip155:137")!)
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


        let uri = try await dapp.authenticate(AuthRequestParams.stub(chains: ["eip155:1", "eip155:137"]))!

        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [requestExpectation, responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testFalbackForm_2_5_DappToSessionProposeOnWallet() async throws {

        let fallbackExpectation = expectation(description: "fallback to wc_sessionPropose")
        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)


        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do { _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
            }
        }.store(in: &publishers)

        dapp.sessionSettlePublisher.sink { settledSession in
            Task(priority: .high) {
                fallbackExpectation.fulfill()
            }
        }.store(in: &publishers)

        let uri = try await dapp.authenticate(AuthRequestParams.stub())!
        let uriStringWithoutMethods = uri.absoluteString.replacingOccurrences(of: "&methods=wc_sessionAuthenticate", with: "")
        let uriWithoutMethods = try WalletConnectURI(uriString: uriStringWithoutMethods)
        try await walletPairingClient.pair(uri: uriWithoutMethods)
        await fulfillment(of: [fallbackExpectation], timeout: InputConfig.defaultTimeout)
    }


    func testFallbackToSessionProposeIfWalletIsNotSubscribingSessionAuthenticate()  async throws {
        
        let responseExpectation = expectation(description: "successful response delivered")

        let requiredNamespaces = ProposalNamespace.stubRequired()
        let sessionNamespaces = SessionNamespace.make(toRespond: requiredNamespaces)
        
        wallet.sessionProposalPublisher.sink { [unowned self] (proposal, _) in
            Task(priority: .high) {
                do { _ = try await wallet.approve(proposalId: proposal.id, namespaces: sessionNamespaces) } catch { XCTFail("\(error)") }
            }
        }.store(in: &publishers)

        dapp.sessionSettlePublisher.sink { settledSession in
            Task(priority: .high) {
                responseExpectation.fulfill()
            }
        }.store(in: &publishers)

        let uri = try await dapp.authenticate(AuthRequestParams.stub())!
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    // Link Mode

    func testLinkAuthRequest() async throws {
        try await setUpDappForLinkMode()
        dappRelayClient.blockPublishing = true
        walletRelayClient.blockPublishing = true

        let responseExpectation = expectation(description: "successful response delivered")

        // Set Wallet's universal link in dapp storage to mock wallet proof on link mode support
        let walletUniversalLink = "https://test"
        let dappLinkModeLinksStore = CodableStore<Bool>(defaults: dappKeyValueStorage, identifier: SignStorageIdentifiers.linkModeLinks.rawValue)
        dappLinkModeLinksStore.set(true, forKey: walletUniversalLink)

        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: walletAccount)

                let signature = try signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                let (_, approveEnvelope) = try! await wallet.approveSessionAuthenticateLinkMode(requestId: request.id, auths: [auth])
                try dapp.dispatchEnvelope(approveEnvelope)
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { (_, result) in
            guard case .success = result else { XCTFail(); return }
            responseExpectation.fulfill()
        }
        .store(in: &publishers)


        let requestEnvelope = try await dapp.authenticateLinkMode(AuthRequestParams.stub(), walletUniversalLink: walletUniversalLink)
        try wallet.dispatchEnvelope(requestEnvelope)
        await fulfillment(of: [responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testLinkSessionRequest() async throws {
        try await setUpDappForLinkMode()
        dappRelayClient.blockPublishing = true
        walletRelayClient.blockPublishing = true
        let requestExpectation = expectation(description: "Wallet expects to receive a request")
        let responseExpectation = expectation(description: "Dapp expects to receive a response")

        let requestMethod = "personal_sign"
        let requestParams = [EthSendTransaction.stub()]
        let responseParams = "0xdeadbeef"

        let semaphore = DispatchSemaphore(value: 0)

        // Set Wallet's universal link in dapp storage to mock wallet proof on link mode support
        let walletUniversalLink = "https://test"
        let dappLinkModeLinksStore = CodableStore<Bool>(defaults: dappKeyValueStorage, identifier: SignStorageIdentifiers.linkModeLinks.rawValue)
        dappLinkModeLinksStore.set(true, forKey: walletUniversalLink)

        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: walletAccount)

                let signature = try signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                let (_, approveEnvelope) = try! await wallet.approveSessionAuthenticateLinkMode(requestId: request.id, auths: [auth])
                try dapp.dispatchEnvelope(approveEnvelope)
                semaphore.signal()
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { [unowned self] (_, result) in
            semaphore.wait()
            guard case .success(let (session, _)) = result,
                let session = session else { XCTFail(); return }
            Task(priority: .high) {
                let request = try! Request(id: RPCID(0), topic: session.topic, method: requestMethod, params: requestParams, chainId: Blockchain("eip155:1")!)
                let requestEnvelope = try! await dapp.requestLinkMode(params: request)!
                try! wallet.dispatchEnvelope(requestEnvelope)
                semaphore.signal()
            }
        }
        .store(in: &publishers)

        wallet.sessionRequestPublisher.sink { [unowned self] (sessionRequest, _) in
            semaphore.wait()
            let receivedParams = try! sessionRequest.params.get([EthSendTransaction].self)
            XCTAssertEqual(receivedParams, requestParams)
            XCTAssertEqual(sessionRequest.method, requestMethod)
            requestExpectation.fulfill()
            Task(priority: .high) {
                let envelope = try! await wallet.respondLinkMode(topic: sessionRequest.topic, requestId: sessionRequest.id, response: .response(AnyCodable(responseParams)))!
                try! dapp.dispatchEnvelope(envelope)
            }
            semaphore.signal()
        }.store(in: &publishers)

        dapp.sessionResponsePublisher.sink { response in
            semaphore.wait()
            switch response.result {
            case .response(let response):
                XCTAssertEqual(try! response.get(String.self), responseParams)
            case .error:
                XCTFail()
            }
            responseExpectation.fulfill()
        }.store(in: &publishers)

        let requestEnvelope = try await dapp.authenticateLinkMode(AuthRequestParams.stub(), walletUniversalLink: walletUniversalLink)
        try wallet.dispatchEnvelope(requestEnvelope)
        
        await fulfillment(of: [requestExpectation, responseExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testLinkModeFailsWhenDappDoesNotHaveProofThatWalletSupportsLinkMode() async throws {
        // ensure link mode fails before the upgrade
        do {
            try await self.dapp.authenticateLinkMode(AuthRequestParams.stub(), walletUniversalLink: self.walletLinkModeUniversalLink)
            XCTFail("Expected error but got success.")
        } catch {
            if let authError = error as? LinkAuthRequester.Errors, authError == .walletLinkSupportNotProven {
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testUpgradeFromRelayToLinkMode() async throws {
        try await setUpDappForLinkMode()

        let linkModeUpgradeExpectation = expectation(description: "successful upgraded to link mode")
        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in
            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: walletAccount)

                let signature = try signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                _ = try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [auth])
                walletRelayClient.blockPublishing = true
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { [unowned self] (_, result) in
            dappRelayClient.blockPublishing = true
            guard case .success = result else { XCTFail(); return }


            Task { [unowned self] in
                try! await self.dapp.authenticateLinkMode(AuthRequestParams.stub(), walletUniversalLink: self.walletLinkModeUniversalLink)
                linkModeUpgradeExpectation.fulfill()
            }
        }
        .store(in: &publishers)


        let uri = try await dapp.authenticate(AuthRequestParams.stub(), walletUniversalLink: walletLinkModeUniversalLink)!
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [linkModeUpgradeExpectation], timeout: InputConfig.defaultTimeout)
    }

    func testUpgradeSessionToLinkModeAndSendRequestOverLinkMode() async throws {

        try await setUpDappForLinkMode()
        let requestMethod = "personal_sign"
        let requestParams = [EthSendTransaction.stub()]
        let sessionResponseOnLinkModeExpectation = expectation(description: "Dapp expects to receive a response")

        let responseParams = "0xdeadbeef"
        let semaphore = DispatchSemaphore(value: 0)

        wallet.authenticateRequestPublisher.sink { [unowned self] (request, _) in

            Task(priority: .high) {
                let signerFactory = DefaultSignerFactory()
                let signer = MessageSignerFactory(signerFactory: signerFactory).create()

                let supportedAuthPayload = try! wallet.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

                let siweMessage = try! wallet.formatAuthMessage(payload: supportedAuthPayload, account: walletAccount)

                let signature = try signer.sign(
                    message: siweMessage,
                    privateKey: prvKey,
                    type: .eip191)

                let auth = try wallet.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: walletAccount)

                _ = try! await wallet.approveSessionAuthenticate(requestId: request.id, auths: [auth])
                semaphore.signal()
            }
        }
        .store(in: &publishers)
        dapp.authResponsePublisher.sink { [unowned self] (_, result) in
            semaphore.wait()
            dappRelayClient.blockPublishing = true
            walletRelayClient.blockPublishing = true
            guard case .success(let (session, _)) = result,
                let session = session else { XCTFail(); return }

            Task { [unowned self] in
                let request = try! Request(id: RPCID(0), topic: session.topic, method: requestMethod, params: requestParams, chainId: Blockchain("eip155:1")!)
                let requestEnvelope = try! await self.dapp.requestLinkMode(params: request)!
                try! self.wallet.dispatchEnvelope(requestEnvelope)
            }
        }
        .store(in: &publishers)

        wallet.sessionRequestPublisher.sink { [unowned self] (sessionRequest, _) in
            Task(priority: .high) {
                let envelope = try! await wallet.respondLinkMode(topic: sessionRequest.topic, requestId: sessionRequest.id, response: .response(AnyCodable(responseParams)))!
                try! dapp.dispatchEnvelope(envelope)
            }
        }.store(in: &publishers)

        dapp.sessionResponsePublisher.sink { response in
            sessionResponseOnLinkModeExpectation.fulfill()
        }.store(in: &publishers)

        let uri = try await dapp.authenticate(AuthRequestParams.stub(), walletUniversalLink: walletLinkModeUniversalLink)!
        try await walletPairingClient.pair(uri: uri)
        await fulfillment(of: [sessionResponseOnLinkModeExpectation], timeout: InputConfig.defaultTimeout)
    }

}
