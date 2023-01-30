import XCTest
import Combine
import JSONRPC
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS
@testable import WalletConnectPairing
import WalletConnectUtils

func deriveTopic(publicKey: String, privateKey: AgreementPrivateKey) -> String {
    try! KeyManagementService.generateAgreementKey(from: privateKey, peerPublicKey: publicKey).derivedTopic()
}

final class AppProposalServiceTests: XCTestCase {

    var service: AppProposeService!

    var appPairService: AppPairService!
    var pairingRegisterer: PairingRegistererMock<SessionProposal>!
    var approveEngine: ApproveEngine!

    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!

    var topicGenerator: TopicGenerator!
    var publishers = Set<AnyCancellable>()

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
        pairingRegisterer = PairingRegistererMock()
        setupServices()
    }

    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        topicGenerator = nil
        pairingRegisterer = nil
        approveEngine = nil
    }

    func setupServices() {
        let meta = AppMetadata.stub()
        let logger = ConsoleLoggerMock()

        appPairService = AppPairService(
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            pairingStorage: storageMock
        )
        service = AppProposeService(
            metadata: .stub(),
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            logger: logger
        )
        approveEngine = ApproveEngine(
            networkingInteractor: networkingInteractor,
            proposalPayloadsStore: .init(defaults: RuntimeKeyValueStorage(), identifier: ""),
            sessionTopicToProposal: CodableStore<Session.Proposal>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            pairingRegisterer: pairingRegisterer,
            metadata: meta,
            kms: cryptoMock,
            logger: logger,
            pairingStore: storageMock,
            sessionStore: WCSessionStorageMock()
        )
    }

    func testPropose() async {
        let pairing = Pairing.stub()
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)

        // FIXME: namespace stub
        try! await service.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)

        guard let publishTopic = networkingInteractor.requests.first?.topic,
              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
                  XCTFail("Proposer must publish a proposal request."); return
              }
        XCTAssert(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must store the private key matching the public key sent through the proposal.")
        XCTAssertEqual(publishTopic, topicA)
    }

    func testHandleSessionProposeResponse() async {
        let exp = expectation(description: "testHandleSessionProposeResponse")
        let uri = try! await appPairService.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)

        // Client proposes session
        // FIXME: namespace stub
        try! await service.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)

        guard let request = networkingInteractor.requests.first?.request,
              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
                  XCTFail("Proposer must publish session proposal request"); return
              }

        // Client receives proposal response response
        let responder = Participant.stub()
        let proposalResponse = SessionType.ProposeResponse(relay: relayOptions, responderPublicKey: responder.publicKey)

        let response = RPCResponse(id: request.id!, result: RPCResult.response(AnyCodable(proposalResponse)))

        networkingInteractor.onSubscribeCalled = {
            exp.fulfill()
        }

        networkingInteractor.responsePublisherSubject.send((topicA, request, response))
        let privateKey = try! cryptoMock.getPrivateKey(for: proposal.proposer.publicKey)!
        let topicB = deriveTopic(publicKey: responder.publicKey, privateKey: privateKey)
        _ = storageMock.getPairing(forTopic: topicA)!

        wait(for: [exp], timeout: 5)

        let sessionTopic = networkingInteractor.subscriptions.last!

        XCTAssertTrue(networkingInteractor.didCallSubscribe)
        XCTAssertEqual(topicB, sessionTopic, "Responder engine calls back with session topic")
    }

    func testSessionProposeError() async {
        let uri = try! await appPairService.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)

        // Client propose session
        // FIXME: namespace stub
        try! await service.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)

        guard let request = networkingInteractor.requests.first?.request,
              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
                  XCTFail("Proposer must publish session proposal request"); return
              }

        let response = RPCResponse.stubError(forRequest: request)
        networkingInteractor.responsePublisherSubject.send((topicA, request, response))

        XCTAssert(networkingInteractor.didUnsubscribe(to: pairing.topic), "Proposer must unsubscribe if pairing is inactive.")
        XCTAssertFalse(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must delete an inactive pairing.")
        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must delete symmetric key if pairing is inactive.")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
    }

    func testSessionProposeErrorOnActivePairing() async {
        let uri = try! await appPairService.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        let topicA = pairing.topic
        let relayOptions = RelayProtocolOptions(protocol: "", data: nil)

        // Client propose session
        // FIXME: namespace stub
        try? await service.propose(pairingTopic: pairing.topic, namespaces: ProposalNamespace.stubDictionary(), relay: relayOptions)

        guard let request = networkingInteractor.requests.first?.request,
              let proposal = try? networkingInteractor.requests.first?.request.params?.get(SessionType.ProposeParams.self) else {
                  XCTFail("Proposer must publish session proposal request"); return
              }

        var storedPairing = storageMock.getPairing(forTopic: topicA)!
        storedPairing.activate()
        storageMock.setPairing(storedPairing)

        let response = RPCResponse.stubError(forRequest: request)
        networkingInteractor.responsePublisherSubject.send((topicA, request, response))

        XCTAssertFalse(networkingInteractor.didUnsubscribe(to: pairing.topic), "Proposer must not unsubscribe if pairing is active.")
        XCTAssert(storageMock.hasPairing(forTopic: pairing.topic), "Proposer must not delete an active pairing.")
        XCTAssert(cryptoMock.hasSymmetricKey(for: pairing.topic), "Proposer must not delete symmetric key if pairing is active.")
        XCTAssertFalse(cryptoMock.hasPrivateKey(for: proposal.proposer.publicKey), "Proposer must remove private key for rejected session")
    }
}
