import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnect


class NonControllerSessionStateMachineTests: XCTestCase {
    var sut: NonControllerSessionStateMachine!
    var relayMock: MockedWCRelay!
    var storageMock: WCSessionStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        storageMock = WCSessionStorageMock()
        cryptoMock = KeyManagementServiceMock()
        sut = NonControllerSessionStateMachine(relay: relayMock, kms: cryptoMock, sessionStore: storageMock, logger: ConsoleLoggerMock())
    }
    
    override func tearDown() {
        relayMock = nil
        storageMock = nil
        cryptoMock = nil
        sut = nil
    }
    
    // MARK: - Update Accounts
    
    func testUpdatePeerSuccess() {
        let session = WCSession.stub(isSelfController: false)
        storageMock.setSession(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateAccounts(topic: session.topic))
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    func testUpdatePeerErrorAccountInvalid() {
        let session = WCSession.stub(isSelfController: false)
        storageMock.setSession(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateAccounts(topic: session.topic, accounts: ["0"]))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1003)
    }
    
    func testUpdatePeerErrorNoSession() {
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateAccounts(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }

    func testUpdatePeerErrorUnauthorized() {
        let session = WCSession.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSession(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateAccounts(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3003)
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
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: session.topic))
        XCTAssertTrue(didCallbackUpdatMethods)
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    func testUpdateMethodsPeerErrorInvalidType() {
        let invalidMethods: Set<String> = [""]
        let session = WCSession.stub(isSelfController: false)
        storageMock.setSession(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: session.topic, methods: invalidMethods))
        XCTAssertEqual(relayMock.lastErrorCode, 1004)
    }

    func testUpdateMethodPeerErrorSessionNotFound() {
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: ""))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 1301)
    }

    func testUpdateMethodPeerErrorUnauthorized() {
        let session = WCSession.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSession(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateMethods(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3004)
    }
    
    // MARK: - Update Events

    func testUpdateEventsPeerSuccess() {
        var didCallbackUpdateEvents = false
        let session = WCSession.stub(isSelfController: false)
        storageMock.setSession(session)
        sut.onEventsUpdate = { topic, _ in
            didCallbackUpdateEvents = true
            XCTAssertEqual(topic, session.topic)
        }
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateEvents(topic: session.topic))
        XCTAssertTrue(didCallbackUpdateEvents)
        XCTAssertTrue(relayMock.didRespondSuccess)
    }
    
    
    func testUpdateEventsPeerErrorUnauthorized() {
        let session = WCSession.stub(isSelfController: true) // Peer is not a controller
        storageMock.setSession(session)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateEvents(topic: session.topic))
        XCTAssertFalse(relayMock.didRespondSuccess)
        XCTAssertEqual(relayMock.lastErrorCode, 3005)
    }
    
    //MARK: - Update Expiry
    
    func testPeerUpdateExpirySuccess() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970)
        
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: twoDaysFromNowTimestamp))
        let extendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        print(extendedSession.expiryDate)
        
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSince1970, TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970, accuracy: 1)
    }
    
    func testPeerUpdateExpiryUnauthorized() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 2).timeIntervalSince1970)

        
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: twoDaysFromNowTimestamp))

        
        let potentiallyExtendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentiallyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended for peer non controller request ")
    }
    
    func testPeerUpdateExpiryTtlTooHigh() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let tenDaysFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 10).timeIntervalSince1970)
        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: tenDaysFromNowTimestamp))

        let potentaillyExtendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended despite ttl to high")
    }

    func testPeerUpdateExpiryTtlTooLow() {
        let tomorrow = TimeTraveler.dateByAdding(days: 2)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let oneDayFromNowTimestamp = Int64(TimeTraveler.dateByAdding(days: 10).timeIntervalSince1970)

        relayMock.wcRequestPublisherSubject.send(WCRequestSubscriptionPayload.stubUpdateExpiry(topic: session.topic, expiry: oneDayFromNowTimestamp))
        let potentaillyExtendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(potentaillyExtendedSession.expiryDate.timeIntervalSinceReferenceDate, tomorrow.timeIntervalSinceReferenceDate, accuracy: 1, "expiry date has been extended despite ttl to low")
    }
}
