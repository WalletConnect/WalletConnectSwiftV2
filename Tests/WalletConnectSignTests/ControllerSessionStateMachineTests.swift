import XCTest
import WalletConnectUtils
@testable import TestingUtils
import WalletConnectKMS
@testable import WalletConnectSign

class ControllerSessionStateMachineTests: XCTestCase {
    var sut: ControllerSessionStateMachine!
    var networkingInteractor: NetworkingInteractorMock!
    var storageMock: WCSessionStorageMock!
    var cryptoMock: KeyManagementServiceMock!

    override func setUp() {
        networkingInteractor = NetworkingInteractorMock()
        storageMock = WCSessionStorageMock()
        cryptoMock = KeyManagementServiceMock()
        sut = ControllerSessionStateMachine(networkingInteractor: networkingInteractor, kms: cryptoMock, sessionStore: storageMock, logger: ConsoleLoggerMock())
    }

    override func tearDown() {
        networkingInteractor = nil
        storageMock = nil
        cryptoMock = nil
        sut = nil
    }

    // MARK: - Update Methods

    // FIXME: Implement new namespace tests
//    func testUpdateNamespacesSuccess() throws {
//        let session = WCSession.stub(isSelfController: true)
//        storageMock.setSession(session)
//        let namespacesToUpdate: Set<Namespace> = [Namespace(chains: [Blockchain("eip155:11")!], methods: ["m1", "m2"], events: ["e1", "e2"])]
//        try sut.updateNamespaces(topic: session.topic, namespaces: namespacesToUpdate)
//        let updatedSession = storageMock.getSession(forTopic: session.topic)
//        XCTAssertTrue(networkingInteractor.didCallRequest)
//        XCTAssertEqual(namespacesToUpdate, updatedSession?.namespaces)
//    }

    func testUpdateNamespacesErrorSessionNotFound() async {
        await XCTAssertThrowsErrorAsync( try await sut.update(topic: "", namespaces: SessionNamespace.stubDictionary())) { error in
            XCTAssertTrue(error.isNoSessionMatchingTopicError)
        }
    }

//    func testUpdateNamespacesErrorInvalidMethod() {
//        let session = WCSession.stub(isSelfController: true)
//        storageMock.setSession(session)
//        XCTAssertThrowsError(try sut.update(topic: session.topic, namespaces: [Namespace(chains: [Blockchain("eip155:1")!], methods: [""], events: [])])) { error in
//            XCTAssertTrue(error.isInvalidMethodError)
//        }
//    }

    func testUpdateNamespacesErrorCalledByNonController() async {
        let session = WCSession.stub(isSelfController: false)
        storageMock.setSession(session)
        await XCTAssertThrowsErrorAsync( try await sut.update(topic: session.topic, namespaces: SessionNamespace.stubDictionary())) { error in
            XCTAssertTrue(error.isUnauthorizedNonControllerCallError)
        }
    }

    // MARK: - Update Expiry

    func testUpdateExpirySuccess() async {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDays = 2*Time.day
        await XCTAssertNoThrowAsync(try await sut.extend(topic: session.topic, by: Int64(twoDays)))
        let extendedSession = storageMock.getAll().first {$0.topic == session.topic}!
        XCTAssertEqual(extendedSession.expiryDate.timeIntervalSinceReferenceDate, TimeTraveler.dateByAdding(days: 2).timeIntervalSinceReferenceDate, accuracy: 1)
    }

    func testUpdateExpirySessionNotSettled() async {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow, acknowledged: false)
        storageMock.setSession(session)
        let twoDays = 2*Time.day
        await XCTAssertThrowsErrorAsync(try await sut.extend(topic: session.topic, by: Int64(twoDays)))
    }

    func testUpdateExpiryOnNonControllerClient() async {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: false, expiryDate: tomorrow)
        storageMock.setSession(session)
        let twoDays = 2*Time.day
        await XCTAssertThrowsErrorAsync( try await sut.extend(topic: session.topic, by: Int64(twoDays)))
    }

    func testUpdateExpiryTtlTooHigh() async {
        let tomorrow = TimeTraveler.dateByAdding(days: 1)
        let session = WCSession.stub(isSelfController: true, expiryDate: tomorrow)
        storageMock.setSession(session)
        let tenDays = 10*Time.day
        await XCTAssertThrowsErrorAsync( try await sut.extend(topic: session.topic, by: Int64(tenDays)))
    }

    func testUpdateExpiryTtlTooLow() async {
        let dayAfterTommorow = TimeTraveler.dateByAdding(days: 2)
        let session = WCSession.stub(isSelfController: true, expiryDate: dayAfterTommorow)
        storageMock.setSession(session)
        let oneDay = Int64(1*Time.day)
        await XCTAssertThrowsErrorAsync( try await sut.extend(topic: session.topic, by: oneDay))
    }
}
