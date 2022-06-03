import XCTest
import Combine
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

final class ApproveEngineTests: XCTestCase {
    
    var engine: ApproveEngine!
    var networkingInteractor: MockedWCRelay!
    var cryptoMock: KeyManagementServiceMock!
    var storageMock: WCPairingStorageMock!
    var proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>!
    
    var publishers = Set<AnyCancellable>()
    
    override func setUp() {
        networkingInteractor = MockedWCRelay()
        cryptoMock = KeyManagementServiceMock()
        storageMock = WCPairingStorageMock()
        proposalPayloadsStore = CodableStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: "")
        engine = ApproveEngine(
            networkingInteractor: networkingInteractor,
            proposalPayloadsStore: proposalPayloadsStore,
            sessionToPairingTopic: CodableStore<String>(defaults: RuntimeKeyValueStorage(), identifier: ""),
            kms: cryptoMock,
            logger: ConsoleLoggerMock(),
            pairingStore: storageMock
        )
    }
    
    override func tearDown() {
        networkingInteractor = nil
        cryptoMock = nil
        storageMock = nil
        engine = nil
    }
    
    func testApproveProposal() throws {
        // Client receives a proposal
        let topicA = String.generateTopic()
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        let request = WCRequest(method: .sessionPropose, params: .sessionPropose(proposal))
        let payload = WCRequestSubscriptionPayload(topic: topicA, wcRequest: request)
        networkingInteractor.wcRequestPublisherSubject.send(payload)

        let (topicB, _) = try engine.approveProposal(proposerPubKey: proposal.proposer.publicKey, validating: SessionNamespace.stubDictionary())
    
        XCTAssert(cryptoMock.hasAgreementSecret(for: topicB), "Responder must store agreement key for topic B")
        XCTAssertEqual(networkingInteractor.didRespondOnTopic!, topicA, "Responder must respond on topic A")
    }
    
    
    func testReceiveProposal() {
        let pairing = WCPairing.stub()
        let topicA = pairing.topic
        storageMock.setPairing(pairing)
        var sessionProposed = false
        let proposerPubKey = AgreementPrivateKey().publicKey.hexRepresentation
        let proposal = SessionProposal.stub(proposerPubKey: proposerPubKey)
        let request = WCRequest(method: .sessionPropose, params: .sessionPropose(proposal))
        let payload = WCRequestSubscriptionPayload(topic: topicA, wcRequest: request)

        engine.approvePublisher.sink { response in
            switch response {
            case .sessionProposal:
                sessionProposed = true
            default:
                break
            }
        }.store(in: &publishers)

        networkingInteractor.wcRequestPublisherSubject.send(payload)
        XCTAssertNotNil(try! proposalPayloadsStore.get(key: proposal.proposer.publicKey), "Proposer must store proposal payload")
        XCTAssertTrue(sessionProposed)
    }
}
