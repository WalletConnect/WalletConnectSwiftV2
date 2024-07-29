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
        let jwt = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MjIyMjMyOTYsImlkIjoiQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQSIsIm9yaWdpbiI6Imh0dHBzOi8vd2ViM21vZGFsLmNvbSIsImlzU2NhbSI6ZmFsc2V9.IyIDRId-8Yv6ZkrnHh4BdL7AClNM5brOyGpYbUw9V_SHJqxgEd9UzMlwcOsVoFHxIqgyoYA-ulvANHW0kv_KdA"
        let messageId = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

        let response = try await verifier.verify(attestationJWT: jwt, messageId: messageId)
        XCTAssertEqual(response.origin, "https://web3modal.com")
        XCTAssertEqual(response.isScam, false)
    }

    func testVerifyJWTWithInvalidMessageId() async throws {
        let jwt = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MjIyMjMyOTYsImlkIjoiQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQSIsIm9yaWdpbiI6Imh0dHBzOi8vd2ViM21vZGFsLmNvbSIsImlzU2NhbSI6ZmFsc2V9.IyIDRId-8Yv6ZkrnHh4BdL7AClNM5brOyGpYbUw9V_SHJqxgEd9UzMlwcOsVoFHxIqgyoYA-ulvANHW0kv_KdA"
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
