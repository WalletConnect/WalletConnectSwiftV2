import XCTest
@testable import WalletConnect

// TODO: Mock all dependencies and write tests
class PairingEngineTests: XCTestCase {
    
    var engine: PairingEngine!
    
    var relay: MockedWCRelay!
    var cryptoMock: Crypto!
    var subscriber: MockedSubscriber!
    
    override func setUp() {
        cryptoMock = Crypto(keychain: KeychainStorageMock())
        relay = MockedWCRelay()
        subscriber = MockedSubscriber()
        let meta = AppMetadata(name: nil, description: nil, url: nil, icons: nil)
        let logger = ConsoleLogger()
        let store = SequenceStore<PairingSequence>(storage: RuntimeKeyValueStorage())
        engine = PairingEngine(
            relay: relay,
            crypto: cryptoMock,
            subscriber: subscriber,
            sequencesStore: store,
            isController: false,
            metadata: meta,
            logger: logger)
    }

    override func tearDown() {
        relay = nil
        engine = nil
        cryptoMock = nil
    }
    
//    func testNotifyOnSessionProposal() {
//        let topic = "1234"
//        let proposalExpectation = expectation(description: "on session proposal is called after pairing payload")
////        engine.sequencesStore.create(topic: topic, sequenceState: sequencePendingState)
//        try? engine.sequencesStore.setSequence(pendingPairing)
//        let subscriptionPayload = WCRequestSubscriptionPayload(topic: topic, clientSynchJsonRpc: sessionProposal)
//        engine.onSessionProposal = { (_) in
//            proposalExpectation.fulfill()
//        }
//        subscriber.onRequestSubscription?(subscriptionPayload)
//        waitForExpectations(timeout: 0.01, handler: nil)
//    }
}

fileprivate let sessionProposal = ClientSynchJSONRPC(id: 0,
                                                     jsonrpc: "2.0",
                                                     method: ClientSynchJSONRPC.Method.pairingPayload,
                                                     params: ClientSynchJSONRPC.Params.pairingPayload(PairingType.PayloadParams(request: PairingType.PayloadParams.Request(method: .sessionPropose, params: SessionType.ProposeParams(topic: "", relay: RelayProtocolOptions(protocol: "", params: []), proposer: SessionType.Proposer(publicKey: "", controller: false, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)), signal: SessionType.Signal(method: "", params: SessionType.Signal.Params(topic: "")), permissions: SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []), notifications: SessionType.Notifications(types: [])), ttl: 100)))))

//fileprivate let sequencePendingState = PairingType.SequenceState.pending(PairingType.Pending(status: PairingType.Pending.PendingStatus(rawValue: "proposed")!, topic: "1234", relay: RelayProtocolOptions(protocol: "", params: nil), self: PairingType.Participant(publicKey: ""), proposal: PairingType.Proposal(topic: "", relay: RelayProtocolOptions(protocol: "", params: nil), proposer: PairingType.Proposer(publicKey: "", controller: false), signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")), permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 100)))
//
//fileprivate let pendingPairing = PairingSequence(topic: "1234", relay: RelayProtocolOptions(protocol: "", params: nil), selfParticipant: PairingType.Participant(publicKey: ""), expiryDate: Date(timeIntervalSinceNow: 10), pendingState: PairingSequence.Pending(proposal: PairingType.Proposal(topic: "", relay: RelayProtocolOptions(protocol: "", params: nil), proposer: PairingType.Proposer(publicKey: "", controller: false), signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")), permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 100), status: .proposed))
