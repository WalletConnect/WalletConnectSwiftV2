import XCTest
@testable import WalletConnectSign
@testable import WalletConnectUtils

class InvalidRequestsSanitiserTests: XCTestCase {
    var sanitiser: InvalidRequestsSanitiser!
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
}
