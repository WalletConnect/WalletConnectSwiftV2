import XCTest
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

final class ApproveEngineTests: XCTestCase {
    
    var engine: ApproveEngine!
    var networkingInteractor: MockedWCRelay!
    var cryptoMock: KeyManagementServiceMock!
    
    override func setUp() {
        networkingInteractor = MockedWCRelay()
        cryptoMock = KeyManagementServiceMock()
        engine = ApproveEngine(
            networkingInteractor: networkingInteractor,
            proposalPayloadsStore: .init(defaults: RuntimeKeyValueStorage(), identifier: ""),
            kms: cryptoMock,
            logger: ConsoleLoggerMock()
        )
    }
    
    override func tearDown() {
        networkingInteractor = nil
        cryptoMock = nil
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
}
