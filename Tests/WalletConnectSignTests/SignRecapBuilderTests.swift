import XCTest
@testable import WalletConnectSign

class SignRecapBuilderTests: XCTestCase {

    var requestedRecapUrn: String {
        let requestedRecap: [String: [String: [String: [[String: [String]]]]]] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [[:]],
                    "request/personal_sign": [[:]]
                ]
            ]
        ]
        let encoded = try! JSONEncoder().encode(requestedRecap).base64EncodedString()
        return "urn:recap:\(encoded)"

    }

    func testSessionRecapBuilder_BuildsCorrectRecap() throws {
        // Given
        let supportedChains = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let supportedMethods = ["eth_sendTransaction"]
        let requestedChains = ["eip155:1", "eip155:137"]

        // When
        let result = try SignRecapBuilder.build(requestedSessionRecap: requestedRecapUrn, requestedChains: requestedChains, supportedEVMChains: supportedChains, supportedMethods: supportedMethods)

        // Expected structure after building the recap
        let expectedRecap: [String: [String: [String: [[String: [String]]]]]] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [
                        ["chains": ["eip155:1", "eip155:137"]]
                    ]
                ]
            ]
        ]

        // Then
        let resultEncoded = try! JSONEncoder().encode(result.recapData).base64EncodedString()
        let expectedEncoded = try! JSONEncoder().encode(expectedRecap).base64EncodedString()

        XCTAssertEqual(resultEncoded, expectedEncoded, "The built recap does not match the expected structure.")
    }

    func testSessionRecapBuilder_AllMethodsSupported()  {
        // Given
        let supportedChains = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let supportedMethods = ["eth_sendTransaction", "personal_sign"]
        let requestedChains = ["eip155:1", "eip155:137"]

        let urn = requestedRecapUrn

        // When
        let result = try! SignRecapBuilder.build(requestedSessionRecap: urn, requestedChains: requestedChains, supportedEVMChains: supportedChains, supportedMethods: supportedMethods)

        // Then
        XCTAssertNotNil(result.recapData.att?["eip155"]?["request/eth_sendTransaction"])
        XCTAssertNotNil(result.recapData.att?["eip155"]?["request/personal_sign"])
    }

    func testSessionRecapBuilder_NonEVMChainThrowsError() throws {
        // Given
        let urn = requestedRecapUrn
        let nonEVMChain = Blockchain("solana:1")!
        let supportedMethods = ["eth_sendTransaction"]
        let requestedChains = ["eip155:1", "eip155:137"]

        // Expecting an error to be thrown for the non-EVM chain
        XCTAssertThrowsError(try SignRecapBuilder.build(requestedSessionRecap: urn, requestedChains: requestedChains, supportedEVMChains: [nonEVMChain], supportedMethods: supportedMethods)) { error in
            XCTAssertEqual(error as? SignRecapBuilder.BuilderError, .nonEVMChainNamespace)
        }
    }

    func testSessionRecapBuilder_ExcludesUnsupportedMethods() throws {
        // Given
        let supportedChains = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        // Include an extra method that is not present in the requestedRecapUrn
        let supportedMethods = ["eth_sendTransaction", "extraUnsupportedMethod"]
        let requestedChains = ["eip155:1", "eip155:137"]

        let requestedRecapUrn = self.requestedRecapUrn // Using the previously defined requestedRecapUrn

        // When
        let result = try SignRecapBuilder.build(requestedSessionRecap: requestedRecapUrn, requestedChains: requestedChains, supportedEVMChains: supportedChains, supportedMethods: supportedMethods)

        // Then
        // Verify that the result only contains the "eth_sendTransaction" method and not the "extraUnsupportedMethod"
        XCTAssertTrue(result.recapData.att?["eip155"]?.keys.contains("request/eth_sendTransaction") ?? false, "Result should contain 'eth_sendTransaction'")
        XCTAssertFalse(result.recapData.att?["eip155"]?.keys.contains("request/extraUnsupportedMethod") ?? true, "Result should not contain 'extraUnsupportedMethod'")
    }

    func testSessionRecapBuilder_RetainsAdditionalAttributes() throws {
        // Given
        let requestedRecap: [String: [String: [String: [[String: [String]]]]]] = [
            "att": [
                "eip155": [
                    "request/eth_sendTransaction": [[:]],
                    "request/personal_sign": [[:]]
                ],
                "https://notify.walletconnect.com": [
                    "manage/all-apps-notifications": [[:]]
                ]
            ]
        ]
        let encoded = try! JSONEncoder().encode(requestedRecap).base64EncodedString()
        let urn = "urn:recap:\(encoded)"

        let supportedChains = [Blockchain("eip155:1")!, Blockchain("eip155:137")!]
        let supportedMethods = ["eth_sendTransaction", "personal_sign"]
        let requestedChains = ["eip155:1", "eip155:137"]

        // When
        let result = try SignRecapBuilder.build(requestedSessionRecap: urn, requestedChains: requestedChains, supportedEVMChains: supportedChains, supportedMethods: supportedMethods)

        // Then
        XCTAssertNotNil(result.recapData.att?["eip155"], "EIP155 namespace should be present")
        XCTAssertNotNil(result.recapData.att?["https://notify.walletconnect.com"], "https://notify.walletconnect.com namespace should be retained")
    }
}
