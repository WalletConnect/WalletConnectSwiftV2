import XCTest
@testable import WalletConnectUtils

class RecapFactoryTests: XCTestCase {

    func testCreateRecap() {
        let resource = "eip155:1"
        let actions = ["request/eth_sendTransaction", "request/personal_sign"]

        let recap = RecapFactory.createRecap(resource: resource, actions: actions)

        let expectedOutput: [String: [String: [String: [AnyCodable]]]] = [
            "att": [
                "eip155:1": [
                    "request/eth_sendTransaction": [AnyCodable(RecapFactory.EmptyObject())],
                    "request/personal_sign": [AnyCodable(RecapFactory.EmptyObject())]
                ]
            ]
        ]

        XCTAssertEqual(recap, expectedOutput, "createRecap output did not match the expected output")
    }
}
