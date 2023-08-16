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
    
    func testPairWhenNetworkNotConnectedThrows() async {
        let uri = WalletConnectURI.stub()
        networkingInteractor.networkConnectionStatusPublisherSubject.send(.notConnected)
        await XCTAssertThrowsErrorAsync(try await service.pair(uri))
    }

    func testPairOnSameURIWhenRequestReceivedThrows() async {
        let uri = WalletConnectURI.stub()
        try! await service.pair(uri)
        var pairing = storageMock.getPairing(forTopic: uri.topic)
        pairing?.receivedRequest()
        storageMock.setPairing(pairing!)
        await XCTAssertThrowsErrorAsync(try await service.pair(uri))
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
