import XCTest
@testable import WalletConnectUtils

class RecapStatementBuilderTests: XCTestCase {
    func testSingleResourceKey() {
        let decodedRecap: [String: [String: [String]]] = [
            "eip155": [
                "request/eth_sendTransaction": [],
                "request/personal_sign": []
            ]
        ]

        let encoded = try! JSONEncoder().encode(decodedRecap).base64EncodedString()
        let urn = try! RecapUrn(urn: "urn:recap:\(encoded)")

        let expectedStatement = "I further authorize the stated URI to perform the following actions: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'."

        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testInvertedAction() {
        let decodedRecap: [String: [String: [String]]] = [
            "eip155": [
                "request/personal_sign": [],
                "request/eth_sendTransaction": []
            ]
        ]
        let encoded = try! JSONEncoder().encode(decodedRecap).base64EncodedString()
        let urn = try! RecapUrn(urn: "urn:recap:\(encoded)")

        let expectedStatement = "I further authorize the stated URI to perform the following actions: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'."

        let recapStatement = RecapStatementBuilder.buildRecapStatement(recapUrns: [urn])

        XCTAssertEqual(recapStatement, expectedStatement)
    }

    func testMultipleRecaps() {

    }
}
