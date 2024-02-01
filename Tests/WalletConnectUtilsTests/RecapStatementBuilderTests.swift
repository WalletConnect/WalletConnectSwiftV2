import XCTest
@testable import WalletConnectUtils

class RecapStatementBuilderTests: XCTestCase {
    func testSingleResourceKey() {
        let decodedRecap: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [],
                    "request/personal_sign": []
                ]
            ]
        ]

        let encoded = try! JSONEncoder().encode(decodedRecap).base64EncodedString()
        let urn = try! RecapUrn(urn: "urn:recap:\(encoded)")

        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'."

        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testInvertedAction() {
        let decodedRecap: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155": [
                    "request/personal_sign": [],
                    "request/eth_sendTransaction": []
                ]
            ]
        ]
        let encoded = try! JSONEncoder().encode(decodedRecap).base64EncodedString()
        let urn = try! RecapUrn(urn: "urn:recap:\(encoded)")

        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'."

        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testMultipleRecaps() {
        // First recap structure
        let decodedRecap1: [String: [String: [String: [String]]]] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [],
                    "request/personal_sign": []
                ]
            ]
        ]

        // Second recap structure, as provided
        let decodedRecap2: [String: [String: [String: [String]]]] = [
            "att": [
                "https://example.com/pictures/": [
                    "crud/delete": [],
                    "crud/update": [],
                    "other/action": []
                ]
            ]
        ]

        // Encoding both recaps
        let encoded1 = try! JSONEncoder().encode(decodedRecap1).base64EncodedString()
        let encoded2 = try! JSONEncoder().encode(decodedRecap2).base64EncodedString()

        // Creating URNs
        let urn1 = try! RecapUrn(urn: "urn:recap:\(encoded1)")
        let urn2 = try! RecapUrn(urn: "urn:recap:\(encoded2)")

        // Expected statement combining both recaps
        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'. (2) 'crud': 'delete', 'update' for 'https://example.com/pictures/'. (3) 'other': 'action' for 'https://example.com/pictures/'."

        // Generating the recap statement from both URNs
        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn1, urn2])

        // Asserting the generated statement against the expected statement
        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testComplexRecap() {
        // URN with encoded JSON string
        let urnString = "urn:recap:eyJhdHQiOnsiaHR0cHM6Ly9leGFtcGxlLmNvbS9waWN0dXJlcy8iOnsiY3J1ZC9kZWxldGUiOlt7fV0sImNydWQvdXBkYXRlIjpbe31dLCJvdGhlci9hY3Rpb24iOlt7fV19LCJtYWlsdG86dXNlcm5hbWVAZXhhbXBsZS5jb20iOnsibXNnL3JlY2VpdmUiOlt7Im1heF9jb3VudCI6NSwidGVtcGxhdGVzIjpbIm5ld3NsZXR0ZXIiLCJtYXJrZXRpbmciXX1dLCJtc2cvc2VuZCI6W3sidG8iOiJzb21lb25lQGVtYWlsLmNvbSJ9LHsidG8iOiJqb2VAZW1haWwuY29tIn1dfX0sInByZiI6WyJiYWZ5YmVpZ2s3bHkzcG9nNnV1cHhrdTNiNmJ1YmlycjQzNGliNnRmYXltdm94NmdvdGFhYWFhYSJdfQ=="

        let urn = try! RecapUrn(urn: urnString)

        // Expected statement
        let expectedStatement = "I further authorize the stated URI to perform the following actions on my behalf: (1) 'crud': 'delete', 'update' for 'https://example.com/pictures'. (2) 'other': 'action' for 'https://example.com/pictures'. (3) 'msg': 'receive', 'send' for 'mailto:username@example.com'."

        // Generating the recap statement from the URN
        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        // Asserting the generated statement against the expected statement
        XCTAssertEqual(recapStatement, expectedStatement)
    }


}
