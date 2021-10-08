
import Foundation
import XCTest
@testable import WalletConnect

class SequenceStateTests: XCTestCase {
    var sut: SequenceState!
    
    var authenticator: HMACAutenticating!

    override func tearDown() {
        sut = nil
    }
    
    func testEncodeDecodePairingPending() {
        sut = .pending(pendingPairingStub)
        let encoded = try! JSONEncoder().encode(sut)
        let decoded = try! JSONDecoder().decode(SequenceState.self, from: encoded)
        XCTAssertEqual(decoded, sut)
    }
    
    func testEncodeDecodeSessionPending() {
        sut = .pending(pendingSessionStub)
        let encoded = try! JSONEncoder().encode(sut)
        let decoded = try! JSONDecoder().decode(SequenceState.self, from: encoded)
        XCTAssertEqual(decoded, sut)
    }
    
    func testEncodeDecodePairingSettled() {
        sut = .settled(settledPairingStub)
        let encoded = try! JSONEncoder().encode(sut)
        let decoded = try! JSONDecoder().decode(SequenceState.self, from: encoded)
        XCTAssertEqual(decoded, sut)
    }
    
    func testEncodeDecodeSessionSettled() {
        sut = .settled(settledSessionStub)
        let encoded = try! JSONEncoder().encode(sut)
        let decoded = try! JSONDecoder().decode(SequenceState.self, from: encoded)
        XCTAssertEqual(decoded, sut)
    }
}




fileprivate let pendingPairingStub = PairingType.Pending(status: .proposed,
                                                          topic: "1234",
                                                          relay: RelayProtocolOptions(protocol: "",
                                                                                      params: nil),
                                                          self: PairingType.Participant(publicKey: ""),
                                                          proposal: PairingType.Proposal(topic: "",
                                                                                         relay: RelayProtocolOptions(protocol: "",
                                                                                                                     params: nil),
                                                                                         proposer: PairingType.Proposer(publicKey: "",
                                                                                                                        controller: false),
                                                                                         signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")),
                                                                                         permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 0))

fileprivate let settledPairingStub = PairingType.Settled(topic: "5678",
                                                          relay: RelayProtocolOptions(protocol: "",
                                                                                      params: nil),
                                                          self: PairingType.Participant(publicKey: ""),
                                                          peer: PairingType.Participant(publicKey: ""),
                                                          permissions: PairingType.Permissions(jsonrpc: PairingType.JSONRPC(methods: []), controller: Controller(publicKey: "")),
                                                          expiry: 0,
                                                          state: nil)

fileprivate let pendingSessionStub = SessionType.Pending(status: .proposed,
                                                          topic: "1234",
                                                          relay: RelayProtocolOptions(protocol: "",
                                                                                      params: nil),
                                                         self: SessionType.Participant(publicKey: "", metadata: nil),
                                                          proposal: SessionType.Proposal(topic: "", relay: RelayProtocolOptions(protocol: "", params: nil), proposer: SessionType.Proposer(publicKey: "", controller: true, metadata: AppMetadata(name: nil, description: nil, url: nil, icons: nil)), signal: SessionType.Signal(method: "", params: SessionType.Signal.Params(topic: "")), permissions: SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: [])), ttl: 0))

fileprivate let settledSessionStub = SessionType.Settled(topic: "",
                                                         relay: RelayProtocolOptions(protocol: "", params: nil), self: SessionType.Participant(publicKey: "", metadata: nil), peer: SessionType.Participant(publicKey: "", metadata: nil), permissions: SessionType.Permissions(blockchain: SessionType.Blockchain(chains: []), jsonrpc: SessionType.JSONRPC(methods: [])), expiry: 0, state: SessionType.State(accounts: []))
