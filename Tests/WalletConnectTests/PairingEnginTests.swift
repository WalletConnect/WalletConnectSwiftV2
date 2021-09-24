
import Foundation
import XCTest
@testable import WalletConnect

class PairingEngineTests: XCTestCase {
    var engine: PairingEngine!
    var relay: MockedRelay!
    var crypto: Crypto!
    var subscriber: MockedSubscriber!
    
    override func setUp() {
        crypto = Crypto(keychain: DictionaryKeychain())
        relay = MockedRelay()
        subscriber = MockedSubscriber()
        engine = PairingEngine(relay: relay, crypto: crypto, subscriber: subscriber, isController: false)
    }

    override func tearDown() {
        relay = nil
        engine = nil
        crypto = nil
    }
    
    func testNotifyOnSessionProposal() {
        let topic = "1234"
        let proposalExpectation = expectation(description: "on session proposal is called after pairing payload")
        engine.sequences.create(topic: topic, sequenceState: sequencePendingState)
        let subscriptionPayload = WCSubscriptionPayload(topic: topic, subscriptionId: "", clientSynchJsonRpc: sessionProposal)
        engine.onSessionProposal = { (_) in
            proposalExpectation.fulfill()
        }
        subscriber.onSubscription?(subscriptionPayload)
        waitForExpectations(timeout: 0.001, handler: nil)
    }
}

fileprivate let sessionProposal = ClientSynchJSONRPC(id: 0,
                                                     jsonrpc: "2.0",
                                                     method: ClientSynchJSONRPC.Method.pairingPayload,
                                                     params: ClientSynchJSONRPC.Params.pairingPayload(PairingType.PayloadParams(request: PairingType.PayloadParams.Request(method: .sessionPropose, params: JSONRPCRequest<SessionType.ProposeParams>(method: "wc_sessionPropose", params: SessionType.ProposeParams(topic: "", relay: RelayProtocolOptions(protocol: "", params: []), proposer: SessionType.Proposer(publicKey: "", controller: false, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)), signal: SessionType.Signal(method: "", params: SessionType.Signal.Params(topic: "")), permissions: SessionType.ProposedPermissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: []), notifications: SessionType.Notifications(types: [])), ttl: 100))))))

fileprivate let sequencePendingState = SequenceState.pending(PairingType.Pending(status: PairingType.Pending.PendingStatus(rawValue: "proposed")!, topic: "1234", relay: RelayProtocolOptions(protocol: "", params: nil), self: PairingType.Participant(publicKey: ""), proposal: PairingType.Proposal(topic: "", relay: RelayProtocolOptions(protocol: "", params: nil), proposer: PairingType.Proposer(publicKey: "", controller: false), signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")), permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 100)))
