import XCTest
@testable import WalletConnectSign
@testable import WalletConnectUtils

final class InvalidRequestsSanitiserTests: XCTestCase {
    var sanitiser: InvalidRequestsSanitiserProtocol!
    var mockHistoryService: MockHistoryService!
    var mockRPCHistory: MockRPCHistory!

    override func setUp() {
        super.setUp()
        mockHistoryService = MockHistoryService()
        mockRPCHistory = MockRPCHistory()
        sanitiser = InvalidRequestsSanitiser(historyService: mockHistoryService, history: mockRPCHistory)
    }

    override func tearDown() {
        sanitiser = nil
        mockHistoryService = nil
        mockRPCHistory = nil
        super.tearDown()
    }
    
    // MARK: - removeInvalidSessionRequests

    func testRemoveInvalidSessionRequests_noPendingRequests() {
        let validSessionTopics: Set<String> = ["validTopic1", "validTopic2"]

        sanitiser.removeInvalidSessionRequests(validSessionTopics: validSessionTopics)

        XCTAssertTrue(mockRPCHistory.deletedTopics.isEmpty)
    }

    func testRemoveInvalidSessionRequests_allRequestsValid() {
        let validSessionTopics: Set<String> = ["validTopic1", "validTopic2"]
        mockHistoryService.pendingRequests = [
            (request: try! Request(topic: "validTopic1", method: "method1", params: AnyCodable("params1"), chainId: Blockchain("eip155:1")!), context: nil),
            (request: try! Request(topic: "validTopic2", method: "method2", params: AnyCodable("params2"), chainId: Blockchain("eip155:1")!), context: nil)
        ]

        sanitiser.removeInvalidSessionRequests(validSessionTopics: validSessionTopics)

        XCTAssertTrue(mockRPCHistory.deletedTopics.isEmpty)
    }

    func testRemoveInvalidSessionRequests_someRequestsInvalid() {
        let validSessionTopics: Set<String> = ["validTopic1", "validTopic2"]
        mockHistoryService.pendingRequests = [
            (request: try! Request(topic: "validTopic1", method: "method1", params: AnyCodable("params1"), chainId: Blockchain("eip155:1")!), context: nil),
            (request: try! Request(topic: "invalidTopic1", method: "method2", params: AnyCodable("params2"), chainId: Blockchain("eip155:1")!), context: nil),
            (request: try! Request(topic: "invalidTopic2", method: "method3", params: AnyCodable("params3"), chainId: Blockchain("eip155:1")!), context: nil)
        ]

        sanitiser.removeInvalidSessionRequests(validSessionTopics: validSessionTopics)

        XCTAssertEqual(mockRPCHistory.deletedTopics.sorted(), ["invalidTopic1", "invalidTopic2"])
    }

    func testRemoveInvalidSessionRequests_withEmptyValidSessionTopics() {
        let validSessionTopics: Set<String> = []

        mockHistoryService.pendingRequests = [
            (request: try! Request(topic: "invalidTopic1", method: "method1", params: AnyCodable("params1"), chainId: Blockchain("eip155:1")!), context: nil),
            (request: try! Request(topic: "invalidTopic2", method: "method2", params: AnyCodable("params2"), chainId: Blockchain("eip155:1")!), context: nil)
        ]

        sanitiser.removeInvalidSessionRequests(validSessionTopics: validSessionTopics)

        XCTAssertEqual(mockRPCHistory.deletedTopics.sorted(), ["invalidTopic1", "invalidTopic2"])
    }
    
    // MARK: - removeSessionRequests
    
    func testRemoveSessionRequestsWith_noPendingRequests() {
        sanitiser.removeSessionRequestsWith(topic: "staleTopic1")
        XCTAssertTrue(mockRPCHistory.deletedTopics.isEmpty)
    }

    func testRemoveSessionRequestsWith_singleStalePendingTopics() {
        mockHistoryService.pendingRequests = [
            (
                request: try! Request(
                    topic: "staleTopic1",
                    method: "method1",
                    params: AnyCodable("params1"),
                    chainId: Blockchain("eip155:1")!
                ),
                context: nil
            ),
            (
                request: try! Request(
                    topic: "validTopic2",
                    method: "method2",
                    params: AnyCodable("params2"),
                    chainId: Blockchain("eip155:1")!
                ),
                context: nil
            )
        ]
        
        sanitiser.removeSessionRequestsWith(topic: "staleTopic1")
        
        XCTAssertEqual(mockRPCHistory.deletedTopics.sorted(), ["staleTopic1"])
    }

    func testRemoveSessionRequestsWith_noMatchingStaleTopics() {
        mockHistoryService.pendingRequests = [
            (
                request: try! Request(
                    topic: "validTopic1",
                    method: "method1",
                    params: AnyCodable("params1"),
                    chainId: Blockchain("eip155:1")!
                ),
                context: nil
            ),
            (
                request: try! Request(
                    topic: "validTopic2",
                    method: "method2",
                    params: AnyCodable("params2"),
                    chainId: Blockchain("eip155:1")!
                ),
                context: nil
            ),
            (
                request: try! Request(
                    topic: "validTopic3",
                    method: "method3",
                    params: AnyCodable("params3"),
                    chainId: Blockchain("eip155:1")!
                ),
                context: nil
            )
        ]

        sanitiser.removeSessionRequestsWith(topic: "staleTopic1")

        XCTAssertTrue(mockRPCHistory.deletedTopics.isEmpty)
    }
}
