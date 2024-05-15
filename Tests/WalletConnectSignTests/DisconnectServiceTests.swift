import XCTest
@testable import WalletConnectSign
@testable import WalletConnectUtils

final class DisconnectServiceTests: XCTestCase {
   
    var mockDeleteSessionService: MockDeleteSessionService!
    var mockStorage: WCSessionStorageMock!
    var mockSanitiser: MockInvalidRequestsSanitiser!
    var sut: DisconnectService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockDeleteSessionService = MockDeleteSessionService()
        mockStorage = WCSessionStorageMock()
        mockSanitiser = MockInvalidRequestsSanitiser()
        sut = DisconnectService(
            deleteSessionService: mockDeleteSessionService,
            sessionStorage: mockStorage,
            invalidRequestsSanitiser: mockSanitiser
        )
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockSanitiser = nil
        mockStorage = nil
        mockDeleteSessionService = nil
        
        try super.tearDownWithError()
    }
    
    func test_disconnect_clears_requests_for_topic() async throws {
        let topicsToRemove = [ "topic1", "topic2", "topic3" ]
        
        for topic in topicsToRemove {
            mockStorage.setSession(
                WCSession.stub(
                    topic: topic,
                    namespaces: SessionNamespace.stubDictionary()
                )
            )
        }
        
        for topic in topicsToRemove {
            try await sut.disconnect(topic: topic)
        }
        
        XCTAssertEqual(mockSanitiser.removedTopics, topicsToRemove)
    }
}
