import Foundation
import XCTest
@testable import Auth
import JSONRPC
import TestingUtils

class EIP1271VerifierTests: XCTestCase {

    let signature = Data(hex: "c1505719b2504095116db01baaf276361efd3a73c28cf8cc28dabefa945b8d536011289ac0a3b048600c1e692ff173ca944246cf7ceb319ac2262d27b395c82b1c")
    let message = Data(hex: "3aaa8393796c7388e4e062861d8238503de7584c977676fe9d8d551c30e11f84")
    let address = "0x2faf83c542b68f1b4cdc0e770e8cb9f567b08f71"

    func testSuccessVerify() async throws {
        let response = RPCResponse(id: "1", result: "0x1626ba7e00000000000000000000000000000000000000000000000000000000")
        let httpClient = HTTPClientMock(object: response)
        let verifier = EIP1271Verifier(projectId: "project-id", httpClient: httpClient)
        try await verifier.verify(
            signature: signature,
            message: message,
            address: address
        )
    }

    func testFailureVerify() async throws {
        let response = RPCResponse(id: "1", error: .internalError)
        let httpClient = HTTPClientMock(object: response)
        let verifier = EIP1271Verifier(projectId: "project-id", httpClient: httpClient)

        await XCTAssertThrowsErrorAsync(try await verifier.verify(
            signature: signature,
            message: message,
            address: address
        ))
    }
}
