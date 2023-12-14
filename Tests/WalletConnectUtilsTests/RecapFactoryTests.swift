import XCTest
@testable import WalletConnectUtils // Replace with your actual module name

class RecapFactoryTests: XCTestCase {

    func testCreateRecap() {
        // Define the input values
        let resource = "eip155:1"
        let actions = ["request/eth_sendTransaction", "request/personal_sign"]

        // Call the function
        let recap = RecapFactory.createRecap(resource: resource, actions: actions)

        // Define the expected output
        let expectedOutput: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155:1": [
                    "request/eth_sendTransaction": [],
                    "request/personal_sign": []
                ]
            ]
        ]

        // Assert that the output equals the expected output
        XCTAssertEqual(recap, expectedOutput, "createRecap output did not match the expected output")
    }
}
