import XCTest
@testable import WalletConnectPairing
@testable import TestingUtils
@testable import WalletConnectKMS
import WalletConnectUtils
import WalletConnectNetworking

final class ExpirationServiceTestsTests: XCTestCase {

    var service: ExpirationService!
    var appPairService: AppPairService!
    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCPairingStorageMock!
    var cryptoMock: KeyManagementServiceMock!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        service = ExpirationService(
            pairingStorage: storageMock,
            networkInteractor: networkingInteractor,
            kms: cryptoMock
        )
        appPairService = AppPairService(
            networkingInteractor: networkingInteractor,
            kms: cryptoMock,
            pairingStorage: storageMock
        )
    }

    func testPairingExpiration() async {
        let uri = try! await appPairService.create()
        let pairing = storageMock.getPairing(forTopic: uri.topic)!
        service.setupExpirationHandling()
        storageMock.onPairingExpiration?(pairing)
        XCTAssertFalse(cryptoMock.hasSymmetricKey(for: uri.topic))
        XCTAssert(networkingInteractor.didUnsubscribe(to: uri.topic))
    }
}
