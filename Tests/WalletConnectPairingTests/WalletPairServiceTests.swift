import XCTest
@testable import WalletConnectPairing
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking

final class WalletPairServiceTestsTests: XCTestCase {

    var service: WalletPairService!
    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        service = WalletPairService(networkingInteractor: networkingInteractor, kms: cryptoMock, pairingStorage: storageMock)
    }

    func testPairMultipleTimesOnSameURIThrows() async {
        let uri = WalletConnectURI.stub()
        for i in 1...10 {
            if i == 1 {
                await XCTAssertNoThrowAsync(try await service.pair(uri))
            } else {
                await XCTAssertThrowsErrorAsync(try await service.pair(uri))
            }
        }
    }

    func testPair() async {
        let uri = WalletConnectURI.stub()
        let topic = uri.topic
        try! await service.pair(uri)
        XCTAssert(networkingInteractor.didSubscribe(to: topic), "Responder must subscribe to pairing topic.")
        XCTAssert(cryptoMock.hasSymmetricKey(for: topic), "Responder must store the symmetric key matching the pairing topic")
        XCTAssert(storageMock.hasPairing(forTopic: topic), "The engine must store a pairing")
    }
}
