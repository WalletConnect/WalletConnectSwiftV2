import XCTest
@testable import WalletConnectSign

class SessionRecapBuilderTests: XCTestCase {

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

        // When
        let result = try SessionRecapBuilder.build(requestedSessionRecap: requestedRecapUrn, supportedEVMChains: supportedChains, supportedMethods: supportedMethods)

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

        let urn = requestedRecapUrn

        // When
        let result = try! SessionRecapBuilder.build(requestedSessionRecap: urn, supportedEVMChains: supportedChains, supportedMethods: supportedMethods)

        // Then
        XCTAssertNotNil(result.recapData.att?["eip155"]?["request/eth_sendTransaction"])
        XCTAssertNotNil(result.recapData.att?["eip155"]?["request/personal_sign"])
    }

    func testSessionRecapBuilder_NonEVMChainThrowsError() throws {
        // Given
        let urn = requestedRecapUrn
        let nonEVMChain = Blockchain("solana:1")!
        let supportedMethods = ["eth_sendTransaction"]

        // Expecting an error to be thrown for the non-EVM chain
        XCTAssertThrowsError(try SessionRecapBuilder.build(requestedSessionRecap: urn, supportedEVMChains: [nonEVMChain], supportedMethods: supportedMethods)) { error in
            XCTAssertEqual(error as? SessionRecapBuilder.BuilderError, .nonEVMChainNamespace)
        }
    }

}
