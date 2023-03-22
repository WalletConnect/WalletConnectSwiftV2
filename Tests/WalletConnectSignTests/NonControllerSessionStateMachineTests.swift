import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
import JSONRPC
@testable import WalletConnectSign

class NonControllerSessionStateMachineTests: XCTestCase {
    var sut: NonControllerSessionStateMachine!
    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCSessionStorageMock!
    var cryptoMock: KeyManagementServiceMock!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCSessionStorageMock()
        cryptoMock = KeyManagementServiceMock()
        sut = NonControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: cryptoMock, sessionStore: storageMock, logger: ConsoleLoggerMock())
    }

    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        sut = nil
    }

    // MARK: - Update Methods

    func testUpdateMethodsPeerSuccess() {
        var didCallbackUpdatMethods = false
        let session = WCSession.stub(isSelfController: false)
        storageMock.setSession(session)
        sut.onNamespacesUpdate = { topic, _ in
            didCallbackUpdatMethods = true
            XCTAssertEqual(topic, session.topic)
        }
        networkingInteractor.requestPublisherSubject.send((session.topic, RPCRequest.stubUpdateNamespaces(), Date()))
        XCTAssertTrue(didCallbackUpdatMethods)
        usleep(100)
        XCTAssertTrue(networkingInteractor.didRespondSuccess)
    }

//    func testUpdateMethodsPeerErrorInvalidType() {
//        let session = WCSession.stub(isSelfController: false)
//        storageMock.setSession(session)
//        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateNamespaces(topic: session.topic, namespaces: [
//            Namespace(chains: [Blockchain("eip155:11")!], methods: ["", "m2"], events: ["e1", "e2"])]
// ))
//        XCTAssertEqual(networkingInteractor.lastErrorCode, 1004)
//    }

    func testUpdateMethodPeerErrorSessionNotFound() {
        networkingInteractor.requestPublisherSubject.send(("", RPCRequest.stubUpdateNamespaces(), Date()))
        usleep(100)
        XCTAssertFalse(networkingInteractor.didRespondSuccess)
        XCTAssertEqual(networkingInteractor.lastErrorCode, 7001)
    }

    func testUpdateMethodPeerErrorUnauthorized() {
        let session = WCSession.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSession(session)
        networkingInteractor.requestPublisherSubject.send((session.topic, RPCRequest.stubUpdateNamespaces(), Date()))
        usleep(100)
        XCTAssertFalse(networkingInteractor.didRespondSuccess)
        XCTAssertEqual(networkingInteractor.lastErrorCode, 3003)
    }

    // MARK: - Update Expiry

    func testPeerUpdateExpirySuccess() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970)

        networkingInteractor.requestPublisherSubject.send((session.topic, RPCRequest.stubUpdateExpiry(expiry: twoDaysFromNowTimestamp), Date()))
        let extendedSession = storageMock.getAll().first {$0.topic == session.topic}!
        print(extendedSession.expiryDate)

        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSince1970, TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970, accuracy: 1)
    }

    func testPeerUpdateExpiryUnauthorized() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970)

        networkingInteractor.requestPublisherSubject.send((session.topic, RPCRequest.stubUpdateExpiry(expiry: twoDaysFromNowTimestamp), Date()))

        let potentiallyExtendedSession = storageMock.getAll().first {$0.topic == session.topic}!
        XCTAssertEqual(potentiallyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended for peer non controller request ")
    }

    func testPeerUpdateExpiryTtlTooHigh() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let tenDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 10).timeIntervalSince1970)
        networkingInteractor.requestPublisherSubject.send((session.topic, RPCRequest.stubUpdateExpiry(expiry: tenDaysFromNowTimestamp), Date()))

        let potentaillyExtendedSession = storageMock.getAll().first {$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended despite ttl to high")
    }

    func testPeerUpdateExpiryTtlTooLow() {
        let tomorrow = TimeTraveler.dateByAdding(days: 2)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let oneDayFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 10).timeIntervalSince1970)

        networkingInteractor.requestPublisherSubject.send((session.topic, RPCRequest.stubUpdateExpiry(expiry: oneDayFromNowTimestamp), Date()))
        let potentaillyExtendedSession = storageMock.getAll().first {$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended despite ttl to low")
    }
}
