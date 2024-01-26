import XCTest
@testable import WalletConnectUtils

class RecapFactoryTests: XCTestCase {

    func testCreateRecap() {
        let resource = "eip155:1"
        let actions = ["request/eth_sendTransaction", "request/personal_sign"]

        let recap = RecapFactory.createRecap(resource: resource, actions: actions)

        let expectedOutput: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155:1": [
                    "request/eth_sendTransaction": [],
                    "request/personal_sign": []
                ]
            ]
        ]

        XCTAssertEqual(recap, expectedOutput, "createRecap output did not match the expected output")
    }
}
