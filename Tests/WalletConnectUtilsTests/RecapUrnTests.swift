import XCTest
@testable import WalletConnectUtils

class RecapUrnTests: XCTestCase {
    func testRecapUrnInitializationWithInvalidUrn() {
        let invalidUrn = "urn:invalid:example"

        XCTAssertThrowsError(try RecapUrn(urn: invalidUrn)) { error in
            XCTAssertEqual(error as? RecapUrn.Errors, RecapUrn.Errors.invalidUrn)
        }
    }

    func testRecapUrnInitializationWithInvalidPayload() {
        let invalidPayloadUrn = "urn:recap:invalidPayload"

        XCTAssertThrowsError(try RecapUrn(urn: invalidPayloadUrn)) { error in
            XCTAssertEqual(error as? RecapUrn.Errors, RecapUrn.Errors.invalidJsonStructure)
        }
    }

    func testRecapUrnInitializationSuccess() {
        // Example of a valid RecapData structure encoded to Base64
        let validRecapData: [String: Any] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [],
                    "request/personal_sign": []
                ]
            ]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: validRecapData)
        let base64EncodedJson = jsonData.base64EncodedString()
        let validUrn = "urn:recap:\(base64EncodedJson)"

        XCTAssertNoThrow(try RecapUrn(urn: validUrn))
    }
}
