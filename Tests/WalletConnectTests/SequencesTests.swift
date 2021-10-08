//
//import Foundation
//import XCTest
//@testable import WalletConnect
//
//class SequencesTests: XCTestCase {
//    var sequences: SequencesStore!
//
//    override func setUp() {
//        sequencesStore = Sequences()
//    }
//
//    override func tearDown() {
//        sequencesStore = nil
//    }
//    
//    func testUpdatePendingSequenceToSettled() {
//        sequencesStore.create(topic: "1234", sequenceState: .pending(pendingSequenceStub))
//        sequencesStore.update(topic: "1234", newTopic: "5678", sequenceState: .settled(settledSequenceStub))
//        XCTAssertNotNil(sequences.get(topic: "5678"))
//        XCTAssertNil(sequences.get(topic:"1234"))
//        XCTAssertEqual(sequences.get(topic: "5678")!.sequenceState, .settled(settledSequenceStub))
//    }
//    
//    func testCreateNewSequence() {
//        sequences.create(topic: "1234", sequenceState: .pending(pendingSequenceStub))
//        XCTAssertNotNil(sequences.get(topic: "1234"))
//    }
//}
//
//
//
//fileprivate let pendingSequenceStub = PairingType.Pending(status: .proposed,
//                                                          topic: "1234",
//                                                          relay: RelayProtocolOptions(protocol: "",
//                                                                                      params: nil),
//                                                          self: PairingType.Participant(publicKey: ""),
//                                                          proposal: PairingType.Proposal(topic: "",
//                                                                                         relay: RelayProtocolOptions(protocol: "",
//                                                                                                                     params: nil),
//                                                                                         proposer: PairingType.Proposer(publicKey: "",
//                                                                                                                        controller: false),
//                                                                                         signal: PairingType.Signal(params: PairingType.Signal.Params(uri: "")),
//                                                                                         permissions: PairingType.ProposedPermissions(jsonrpc: PairingType.JSONRPC(methods: [])), ttl: 0))
//
//fileprivate let settledSequenceStub = PairingType.Settled(topic: "5678",
//                                                          relay: RelayProtocolOptions(protocol: "",
//                                                                                      params: nil),
//                                                          self: PairingType.Participant(publicKey: ""),
//                                                          peer: PairingType.Participant(publicKey: ""),
//                                                          permissions: PairingType.Permissions(jsonrpc: PairingType.JSONRPC(methods: []), controller: Controller(publicKey: "")),
//                                                          expiry: 0,
//                                                          state: nil)
