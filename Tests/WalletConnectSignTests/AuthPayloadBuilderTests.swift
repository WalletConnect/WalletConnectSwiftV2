
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

        let result = try AuthPayloadBuilder.build(request: request, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)

        XCTAssertEqual(result.resources?.count, 2, "Expected to have the original non-recap resource and one new session recap URN")
        XCTAssertTrue(result.resources?.contains("other-resource") ?? false, "Expected to preserve non-recap resource")
    }

    func testBuildWithNoValidSessionRecapUrn() throws {
        let request = createSampleAuthPayload(resources: [invalidSessionRecapUrn, "other-resource"])

        XCTAssertThrowsError(try AuthPayloadBuilder.build(request: request, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)) { error in
            guard let error = error as? SessionRecap.Errors else {
                return XCTFail("Expected SessionRecap.Errors")
            }
            XCTAssertEqual(error, SessionRecap.Errors.invalidRecapStructure)
        }
    }

    func testBuildPreservesExtraResources() throws {
        let request = createSampleAuthPayload(resources: ["additional-resource-1", validSessionRecapUrn, "additional-resource-2"])

        let result = try AuthPayloadBuilder.build(request: request, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)

        XCTAssertTrue(result.resources?.contains("additional-resource-1") ?? false && result.resources?.contains("additional-resource-2") ?? false, "Expected to preserve additional non-recap resources")
    }

}
fileprivate func createSampleAuthPayload(domain: String = "example.com",
                             aud: String = "clientID",
                             version: String = "1",
                             nonce: String = "nonce",
                             chains: [String] = ["eip155:1"],
                             type: String = "caip122",
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
