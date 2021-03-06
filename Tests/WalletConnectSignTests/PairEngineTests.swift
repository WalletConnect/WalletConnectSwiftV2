import XCTest
@testable import WalletConnectSign
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

final class PairEngineTests: XCTestCase {

    var engine: PairEngine!

    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    var proposalPayloadsStore: CodableStore<WCRequestSubscriptionPayload>!

    var topicGenerator: TopicGenerator!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        topicGenerator = TopicGenerator()
        proposalPayloadsStore = CodableStore<WCRequestSubscriptionPayload>(defaults: RuntimeKeyValueStorage(), identifier: "")
        setupEngine()
    }

    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        engine = nil
    }

    func setupEngine() {
        engine = PairEngine(
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            pairingStore: storageMock)
    }

    func testPairMultipleTimesOnSameURIThrows() async {
        let uri = WalletConnectURI.stub()
        for i in 1...10 {
            if i == 1 {
                await XCTAssertNoThrowAsync(try await engine.pair(uri))
            } else {
                await XCTAssertThrowsErrorAsync(try await engine.pair(uri))
            }
        }
    }

    func testPair() async {
        let uri = WalletConnectURI.stub()
        let topic = uri.topic
        try! await engine.pair(uri)
        XCTAssert(networkingInteractor.didSubscribe(to: topic), "Responder must subscribe to pairing topic.")
        XCTAssert(cryptoMock.hasSymmetricKey(for: topic), "Responder must store the symmetric key matching the pairing topic")
        XCTAssert(storageMock.hasPairing(forTopic: topic), "The engine must store a pairing")
    }
}
