import XCTest
import CryptoKit
@testable import WalletConnectVerify

class AttestationJWTVerifierTests: XCTestCase {
    var verifier: AttestationJWTVerifier!
    var mockManager: VerifyServerPubKeyManagerMock!

    override func setUp() {
        super.setUp()
        mockManager = VerifyServerPubKeyManagerMock()
        verifier = AttestationJWTVerifier(verifyServerPubKeyManager: mockManager)
    }

    func testVerifyValidJWT() async throws {
        let jwt = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MjM0NzE3MjMsImlkIjoiYjNmYmZhMDUxZDJhNjdkNGRmNTYzM2IyMjc0NDAyNTUxMTg1NzQwZGQwMjA3YWM0OWI1M2RiYTcxOTc0YTgzNCIsIm9yaWdpbiI6Imh0dHBzOi8vcmVhY3QtZGFwcC12Mi1naXQtY2hvcmUtdmVyaWZ5LXYyLXNhbXBsZXMtd2FsbGV0Y29ubmVjdDEudmVyY2VsLmFwcCIsImlzU2NhbSI6bnVsbCwiaXNWZXJpZmllZCI6dHJ1ZX0.8RQwiEEfTGn8p3INRdHpi88dpzetKCp3nscfLtWG2cVE2dU0dWgV2ncqnh_RWmygqEnWCPUlH1RMwS1nWbZzrQ"
        let messageId = "b3fbfa051d2a67d4df5633b2274402551185740dd0207ac49b53dba71974a834"

        let response = try await verifier.verify(attestationJWT: jwt, messageId: messageId)
        XCTAssertEqual(response.origin, "https://react-dapp-v2-git-chore-verify-v2-samples-walletconnect1.vercel.app")
    }

    func testVerifyJWTWithInvalidMessageId() async throws {
        let jwt = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MjM0NzE3MjMsImlkIjoiYjNmYmZhMDUxZDJhNjdkNGRmNTYzM2IyMjc0NDAyNTUxMTg1NzQwZGQwMjA3YWM0OWI1M2RiYTcxOTc0YTgzNCIsIm9yaWdpbiI6Imh0dHBzOi8vcmVhY3QtZGFwcC12Mi1naXQtY2hvcmUtdmVyaWZ5LXYyLXNhbXBsZXMtd2FsbGV0Y29ubmVjdDEudmVyY2VsLmFwcCIsImlzU2NhbSI6bnVsbCwiaXNWZXJpZmllZCI6dHJ1ZX0.8RQwiEEfTGn8p3INRdHpi88dpzetKCp3nscfLtWG2cVE2dU0dWgV2ncqnh_RWmygqEnWCPUlH1RMwS1nWbZzrQ"
        let invalidMessageId = "InvalidMessageId"

        do {
            _ = try await verifier.verify(attestationJWT: jwt, messageId: invalidMessageId)
            XCTFail("Expected to throw messageIdMismatch error")
        } catch AttestationJWTVerifier.Errors.messageIdMismatch {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
