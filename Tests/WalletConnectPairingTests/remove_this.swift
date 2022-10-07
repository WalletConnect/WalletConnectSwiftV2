//import XCTest
//import Combine
//import JSONRPC
//@testable import WalletConnectPairing
//@testable import TestingUtils
//@testable import WalletConnectKMS
//import WalletConnectUtils
//
//func deriveTopic(publicKey: String, privateKey: AgreementPrivateKey) -> String {
//    try! KeyManagementService.generateAgreementKey(from: privateKey, peerPublicKey: publicKey).derivedTopic()
//}
//
//final class WalletPairServiceTests: XCTestCase {
//
//    var service: WalletPairService!
//
//    var networkingInteractor: NetworkingInteractorMock!
//    var storageMock: WCPairingStorageMock!
//    var cryptoMock: KeyManagementServiceMock!
//
//    var publishers = Set<AnyCancellable>()
//
//    override func setUp() {
//        networkingInteractor = NetworkingInteractorMock()
//        storageMock = WCPairingStorageMock()
//        cryptoMock = KeyManagementServiceMock()
//        setupEngines()
//    }
//
//    override func tearDown() {
//        networkingInteractor = nil
//        storageMock = nil
//        cryptoMock = nil
//        service = nil
//    }
//
//    func setupEngines() {
//        service = WalletPairService(networkingInteractor: networkingInteractor, kms: cryptoMock, pairingStorage: storageMock)
//    }
//
//    func testPropose() async {
//        let pairing = Pairing.stub()
//        let topicA = pairing.topic
//        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
//
//        // FIXME: namespace stub
//        try! await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
//
//        guard let publishTopic = networkingInteractor.requests.first?.topic,
//              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
//                  XCTFail("Proposer must publish a proposal request."); return
//              }
//        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must store the private key matching the public key sent through the proposal.")
//        XCTAssertEqual(publishTopic, topicA)
//    }
//
//    func testHandleSessionProposeResponse() async {
//        let exp = expectation(description: "testHandleSessionProposeResponse")
//        let uri = try! await engine.create()
//        let pairing = storageMock.getPairing(forTopic: uri.topic)!
//        let topicA = pairing.topic
//        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
//
//        // Client proposes session
//        // FIXME: namespace stub
//        try! await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
//
//        guard let request = networkingInteractor.requests.first?.request,
//              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
//                  XCTFail("Proposer must publish session proposal request"); return
//              }
//
//        // Client receives proposal response response
//        let responder = Participant.stub()
//        let proposalResponse = SessionType.ProposeResponse(relay: relayOptions, responderPublicKey: responder.publicKey)
//
//        let response = RPCResponse(id: request.id!, result: RPCResult.response(AnyCodable(proposalResponse)))
//
//        networkingInteractor.onSubscribeCalled = {
//            exp.fulfill()
//        }
//
//        networkingInteractor.responsePublisherSubject.send((topicA, request, response))
//        let privateKey = try! cryptoMock.getPrivateKey(for: proposal.proposer.publicKey)!
//        let topicB = deriveTopic(publicKey: responder.publicKey, privateKey: privateKey)
//        let storedPairing = storageMock.getPairing(forTopic: topicA)!
//
//        wait(for: [exp], timeout: 5)
//
//        let sessionTopic = networkingInteractor.subscriptions.last!
//
//        XCTAssertTrue(networkingInteractor.didCallSubscribe)
//        XCTAssert(storedPairing.active)
//        XCTAssertEqual(topicB, sessionTopic, "Responder engine calls back with session topic")
//    }
//
//    func testSessionProposeError() async {
//        let uri = try! await engine.create()
//        let pairing = storageMock.getPairing(forTopic: uri.topic)!
//        let topicA = pairing.topic
//        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
//
//        // Client propose session
//        // FIXME: namespace stub
//        try! await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
//
//        guard let request = networkingInteractor.requests.first?.request,
//              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
//                  XCTFail("Proposer must publish session proposal request"); return
//              }
//
//        let response = RPCResponse.stubError(forRequest: request)
//        networkingInteractor.responsePublisherSubject.send((topicA, request, response))
//
//        XCTAssert(networkingInteractor.didUnsubscribe(to: pairing.topic), "Proposer must unsubscribe if pairing is inactive.")
//        XCTAssertFalse(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must delete an inactive pairing.")
//        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must delete symmetric key if pairing is inactive.")
//        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
//    }
//
//    func testSessionProposeErrorOnActivePairing() async {
//        let uri = try! await engine.create()
//        let pairing = storageMock.getPairing(forTopic: uri.topic)!
//        let topicA = pairing.topic
//        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)
//
//        // Client propose session
//        // FIXME: namespace stub
//        try? await engine.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)
//
//        guard let request = networkingInteractor.requests.first?.request,
//              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
//                  XCTFail("Proposer must publish session proposal request"); return
//              }
//
//        var storedPairing = storageMock.getPairing(forTopic: topicA)!
//        storedPairing.activate()
//        storageMock.setPairing(storedPairing)
//
//        let response = RPCResponse.stubError(forRequest: request)
//        networkingInteractor.responsePublisherSubject.send((topicA, request, response))
//
//        XCTAssertFalse(networkingInteractor.didUnsubscribe(to: pairing.topic), "Proposer must not unsubscribe if pairing is active.")
//        XCTAssert(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must not delete an active pairing.")
//        XCTAssert(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must not delete symmetric key if pairing is active.")
//        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
//    }
//
//    func testPairingExpiration() async {
//        let uri = try! await engine.create()
//        let pairing = storageMock.getPairing(forTopic: uri.topic)!
//        storageMock.onPairingExpiration?(pairing)
//        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: uri.topic))
//        XCTAssert(networkingInteractor.didUnsubscribe(to: uri.topic))
//    }
//}
