import XCTest
@testable import WalletConnectPairing
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils

final class AppPairServiceTests: XCTestCase {

    var service: AppPairService!
    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        service = AppPairService(networkingInteractor: networkingInteractor, kms: cryptoMock, pairingStorage: storageMock)
    }

    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        service = nil
    }

    func testCreate() async {
        let uri = try! await service.create(supportedMethods: nil)
        XCTAssert(cryptoMock.hasSymmetricKey(for: uri.topic), "Proposer must store the symmetric key matching the URI.")
        XCTAssert(storageMock.hasPairing(forTopic: uri.topic), "The engine must store a pairing after creating one")
        XCTAssert(networkingInteractor.didSubscribe(to: uri.topic), "Proposer must subscribe to pairing topic.")
    }
}
