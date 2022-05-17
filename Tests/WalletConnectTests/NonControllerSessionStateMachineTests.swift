import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnect


class NonControllerSessionStateMachineTests: XCTestCase {
    var sut: NonControllerSessionStateMachine!
    var networkingInteractor: MockedWCRelay!
    var storageMock: WCSessionStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    override func setUp() {
        networkingInteractor = MockedWCRelay()
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
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateNamespaces(topic: session.topic))
        XCTAssertTrue(didCallbackUpdatMethods)
        XCTAssertTrue(networkingInteractor.didRespondSuccess)
    }
    
//    func testUpdateMethodsPeerErrorInvalidType() {
//        let session = WCSession.stub(isSelfController: false)
//        storageMock.setSession(session)
//        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateNamespaces(topic: session.topic, namespaces: [
//            Namespace(chains: [Blockchain("eip155:11")!], methods: ["", "m2"], events: ["e1", "e2"])]
//))
//        XCTAssertEqual(networkingInteractor.lastErrorCode, 1004)
//    }

    func testUpdateMethodPeerErrorSessionNotFound() {
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateNamespaces(topic: ""))
        XCTAssertFalse(networkingInteractor.didRespondSuccess)
        XCTAssertEqual(networkingInteractor.lastErrorCode, 1301)
    }

    func testUpdateMethodPeerErrorUnauthorized() {
        let session = WCSession.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSession(session)
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateNamespaces(topic: session.topic))
        XCTAssertFalse(networkingInteractor.didRespondSuccess)
        XCTAssertEqual(networkingInteractor.lastErrorCode, 3004)
    }
    
    //MARK: - Update Expiry
    
    func testPeerUpdateExpirySuccess() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970)
        
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: twoDaysFromNowTimestamp))
        let extendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        print(extendedSession.expiryDate)
        
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSince1970, TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970, accuracy: 1)
    }
    
    func testPeerUpdateExpiryUnauthorized() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970)

        
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: twoDaysFromNowTimestamp))

        
        let potentiallyExtendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentiallyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended for peer non controller request ")
    }
    
    func testPeerUpdateExpiryTtlTooHigh() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let tenDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 10).timeIntervalSince1970)
        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: tenDaysFromNowTimestamp))

        let potentaillyExtendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended despite ttl to high")
    }

    func testPeerUpdateExpiryTtlTooLow() {
        let tomorrow = TimeTraveler.dateByAdding(days: 2)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let oneDayFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 10).timeIntervalSince1970)

        networkingInteractor.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: oneDayFromNowTimestamp))
        let potentaillyExtendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended despite ttl to low")
    }
}
