
import XCTest
@testable import WalletConnectSign

class AuthPayloadBuilderTests: XCTestCase {

    let supportedEVMChains = [Blockchain(namespace: "eip155", reference: "1")!, Blockchain(namespace: "eip155", reference: "137")!]
    let supportedMethods = ["eth_sendTransaction", "personal_sign"]
    // Assuming these URNs based on previous examples and the format of SessionRecap
    let validSessionRecapUrn = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvZXRoX3NpZ24iOltdLCJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOltdLCJyZXF1ZXN0L2V0aF9zaWduVHlwZWREYXRhIjpbXX19fQ=="
    let invalidSessionRecapUrn = "urn:recap:INVALID_BASE64"


    func testBuildWithValidSessionRecapUrn() throws {
        let request = createSampleAuthPayload(resources: [validSessionRecapUrn, "other-resource"])

        let result = try AuthPayloadBuilder.build(payload: request, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)

        XCTAssertEqual(result.resources?.count, 2, "Expected to have the original non-recap resource and one new session recap URN")
        XCTAssertTrue(result.resources?.contains("other-resource") ?? false, "Expected to preserve non-recap resource")
    }

    func testBuildWithNoValidSessionRecapUrn() throws {
        let originalPayload = createSampleAuthPayload(resources: [invalidSessionRecapUrn, "other-resource"])

        let supportedChains = [Blockchain("eip155:1")!]
        let supportedMethods = ["eth_sendTransaction"]

        // When
        let resultPayload = try AuthPayloadBuilder.build(payload: originalPayload, supportedEVMChains: supportedChains, supportedMethods: supportedMethods)

        // Then
        XCTAssertEqual(resultPayload, originalPayload, "Expected the original payload to be returned when no valid session recap URN is found")

    }

    func testBuildPreservesExtraResources() throws {
        let request = createSampleAuthPayload(resources: ["additional-resource-1", validSessionRecapUrn, "additional-resource-2"])

        let result = try AuthPayloadBuilder.build(payload: request, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)

        XCTAssertTrue(result.resources?.contains("additional-resource-1") ?? false && result.resources?.contains("additional-resource-2") ?? false, "Expected to preserve additional non-recap resources")
    }

}
fileprivate func createSampleAuthPayload(domain: String = "example.com",
                             aud: String = "clientID",
                             version: String = "1",
                             nonce: String = "nonce",
                             chains: [String] = ["eip155:1"],
                             type: String = "eip4361",
                             iat: String = "now",
                             nbf: String? = nil,
                             exp: String? = nil,
                             statement: String? = nil,
                             requestId: String? = nil,
                             resources: [String]? = nil) -> AuthPayload {
    return AuthPayload(domain: domain,
                       aud: aud,
                       version: version,
                       nonce: nonce,
                       chains: chains,
                       type: type,
                       iat: iat,
                       nbf: nbf,
                       exp: exp,
                       statement: statement,
                       requestId: requestId,
                       resources: resources)
}
