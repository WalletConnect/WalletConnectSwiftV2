import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnect


class ControllerSessionStateMachineTests: XCTestCase {
    var sut: ControllerSessionStateMachine!
    var relayMock: MockedWCRelay!
    var storageMock: WCSessionStorageMock!
    var cryptoMock: KeyManagementServiceMock!
    
    override func setUp() {
        relayMock = MockedWCRelay()
        storageMock = WCSessionStorageMock()
        cryptoMock = KeyManagementServiceMock()
        sut = ControllerSessionStateMachine(relay: relayMock, kms: cryptoMock, sessionStore: storageMock, logger: ConsoleLoggerMock())
    }
    
    override func tearDown() {
        relayMock = nil
        storageMock = nil
        cryptoMock = nil
        sut = nil
    }
    
    // MARK: - Update Methods
        
    func testUpdateMethodsSuccess() throws {
        let session = WCSession.stub(isSelfController: true)
        storageMock.setSession(session)
        let methodsToUpdate: Set<String> = ["m1", "m2"]
        try sut.updateMethods(topic: session.topic, methods: methodsToUpdate)
        let updatedSession = storageMock.getSession(forTopic: session.topic)
        XCTAssertTrue(relayMock.didCallRequest)
        XCTAssertEqual(methodsToUpdate, updatedSession?.methods)
    }
    
    func testUpdateMethodsErrorSessionNotFound() {
        XCTAssertThrowsError(try sut.updateMethods(topic: "", methods: ["m1"])) { error in
            XCTAssertTrue(error.isNoSessionMatchingTopicError)
        }
    }
    
    func testUpdateMethodsErrorSessionNotAcknowledged() {
        let session = WCSession.stub(acknowledged: false)
        storageMock.setSession(session)
        XCTAssertThrowsError(try sut.updateMethods(topic: session.topic, methods: ["m1"])) { error in
            XCTAssertTrue(error.isSessionNotAcknowledgedError)
        }
    }

    func testUpdateMethodsErrorInvalidMethod() {
        let session = WCSession.stub(isSelfController: true)
        storageMock.setSession(session)
        XCTAssertThrowsError(try sut.updateMethods(topic: session.topic, methods: [""])) { error in
            XCTAssertTrue(error.isInvalidMethodError)
        }
    }

    func testUpdateMethodsErrorCalledByNonController() {
        let session = WCSession.stub(isSelfController: false)
        storageMock.setSession(session)
        XCTAssertThrowsError(try sut.updateMethods(topic: session.topic, methods: ["m1"])) { error in
            XCTAssertTrue(error.isUnauthorizedNonControllerCallError)
        }
    }
    
    // MARK: - Update Events

    func testUpdateEventsSuccess() throws {
        let session = WCSession.stub(isSelfController: true)
        storageMock.setSession(session)
        let eventsToUpdate: Set<String> = ["e1", "e2"]
        try sut.updateEvents(topic: session.topic, events: eventsToUpdate)
        let updatedSession = storageMock.getSession(forTopic: session.topic)!
        XCTAssertTrue(relayMock.didCallRequest)
        XCTAssertEqual(eventsToUpdate, updatedSession.events)
    }
    
    func testUpdateEventsErrorSessionNotFound() {
        XCTAssertThrowsError(try sut.updateEvents(topic: "", events: ["e1"])) { error in
            XCTAssertTrue(error.isNoSessionMatchingTopicError)
        }
    }
        
    // MARK: - Session Update expiry on updating client
    
    func testUpdateExpirySuccess() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDays = 2*Time.day
        XCTAssertNoThrow(try sut.updateExpiry(topic: session.topic, by: Int64(twoDays)))
        let extendedSession = storageMock.getAcknowledgedSessions().first{$0.topic == session.topic}!
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSinceReferenceDate, TimeTraveler.dateByAdding(days: 2).timeIntervalSinceReferenceDate, accuracy: 1)
    }
    
    func testUpdateExpirySessionNotSettled() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow, acknowledged: false)
        storageMock.setSession(session)
        let twoDays = 2*Time.day
        XCTAssertThrowsError(try sut.updateExpiry(topic: session.topic, by: Int64(twoDays)))
    }
    
    func testUpdateExpiryOnNonControllerClient() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDays = 2*Time.day
        XCTAssertThrowsError(try sut.updateExpiry(topic: session.topic, by: Int64(twoDays)))
    }
    
    func testUpdateExpiryTtlTooHigh() {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSession(session)
        let tenDays = 10*Time.day
        XCTAssertThrowsError(try sut.updateExpiry(topic: session.topic, by: Int64(tenDays)))
    }
    
    func testUpdateExpiryTtlTooLow() {
        let dayAfterTommorow = TimeTraveler.dateByAdding(days: 2)
        let session = WCSession.stub(isSelfController: true, expiryDate: dayAfterTommorow)
        storageMock.setSession(session)
        let oneDay = Int64(1*Time.day)
        XCTAssertThrowsError(try sut.updateExpiry(topic: session.topic, by: oneDay))
    }
}
