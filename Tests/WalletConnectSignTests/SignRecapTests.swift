import XCTest
@testable import WalletConnectSign

class SignRecapTests: XCTestCase {

    func testSessionRecapInitializationSuccess() throws {
        // dedoded recap: {"att": {"eip155": {"request/eth_signTypedData_v4": [], "request/personal_sign": []}}}
        let recapUrn = "urn:recap:eyJhdHQiOiB7ImVpcDE1NSI6IHsicmVxdWVzdC9ldGhfc2lnblR5cGVkRGF0YV92NCI6IFtdLCAicmVxdWVzdC9wZXJzb25hbF9zaWduIjogW119fX0="

        do {
            let sessionRecap = try SignRecap(urn: recapUrn)
            let methods = sessionRecap.methods
            // Verify that the expected methods are present
            XCTAssertTrue(methods.contains("personal_sign"))
            XCTAssertTrue(methods.contains("eth_signTypedData_v4"))
        } catch {
            XCTFail("Initialization should not fail for valid recap URN.")
        }
    }

    func testSessionRecapInitializationFailureInvalidRecap() throws {
        // dedoded: {"att": {"eip155:1": {"request/eth_signTypedData_v4": [], "request/personal_sign": []}}}
        let invalidRecap = "urn:recap:eyJhdHQiOiB7ImVpcDE1NToxIjogeyJyZXF1ZXN0L2V0aF9zaWduVHlwZWREYXRhX3Y0IjogW10sICJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOiBbXX19fQ=="

        XCTAssertThrowsError(try SignRecap(urn: invalidRecap)) { error in
            guard let sessionRecapError = error as? SignRecap.Errors else {
                XCTFail("Error should be of type SessionRecap.Errors")
                return
            }

            XCTAssertEqual(sessionRecapError, SignRecap.Errors.invalidRecapStructure)
        }
    }

}
