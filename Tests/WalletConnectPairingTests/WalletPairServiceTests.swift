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
    var rpcHistory: RPCHistory!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCPairingStorageMock()
        cryptoMock = KeyManagementServiceMock()
        rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: RuntimeKeyValueStorage())
        service = WalletPairService(networkingInteractor: networkingInteractor, kms: cryptoMock, pairingStorage: storageMock, history: rpcHistory, logger: ConsoleLoggerMock())
    }
    
    func testPairWhenNetworkNotConnectedThrows() async {
        let uri = WalletConnectURI.stub()
        networkingInteractor.networkConnectionStatusPublisherSubject.send(.notConnected)
        await XCTAssertThrowsErrorAsync(try await service.pair(uri))
    }

    func testPairOnSameUriPresentsRequest() async {
        let rpcRequest = RPCRequest(method: "session_propose", id: 1234)
        
        let uri = WalletConnectURI.stub()
        try! await service.pair(uri)
        var pairing = storageMock.getPairing(forTopic: uri.topic)
        pairing?.receivedRequest()
        storageMock.setPairing(pairing!)
        try! rpcHistory.set(rpcRequest, forTopic: uri.topic, emmitedBy: .local)
        
        try! await service.pair(uri)
        XCTAssertTrue(networkingInteractor.didCallHandleHistoryRequest)
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
