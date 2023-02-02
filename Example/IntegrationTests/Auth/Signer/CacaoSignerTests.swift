import Foundation
import XCTest
@testable import Auth

class CacaoSignerTest: XCTestCase {

    let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory())
        .create(projectId: InputConfig.projectId)

    let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")

    let message: String =
        """
        service.invalid wants you to sign in with your Ethereum account:
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

        I accept the ServiceOrg Terms of Service: https://service.invalid/tos

        URI: https://service.invalid/login
        Version: 1
        Chain ID: 1
        Nonce: 32891756
        Issued At: 2021-09-30T16:25:24Z
        Resources:
        - ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/
        - https://example.com/my-web2-claim.json
        """

    let payload = AuthPayload(requestParams: RequestParams(
        domain: "service.invalid",
        chainId: "eip155:1",
        nonce: "32891756",
        aud: "https://service.invalid/login",
        nbf: nil,
        exp: nil,
        statement: "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
        requestId: nil,
        resources: [
            "ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/",
            "https://example.com/my-web2-claim.json"
        ]
    ), iat: "2021-09-30T16:25:24Z")

    let signature = CacaoSignature(t: .eip191, s: "0x438effc459956b57fcd9f3dac6c675f9cee88abf21acab7305e8e32aa0303a883b06dcbd956279a7a2ca21ffa882ff55cc22e8ab8ec0f3fe90ab45f306938cfa1b")

    func testCacaoSign() throws {
        let address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        let cacaoPayload = try payload.cacaoPayload(address: address)
        let formatted = try SIWECacaoFormatter().formatMessage(from: cacaoPayload)
        XCTAssertEqual(formatted, message)
        XCTAssertEqual(try signer.sign(payload: cacaoPayload, privateKey: privateKey, type: .eip191), signature)
    }

    func testCacaoVerify() async throws {
        try await signer.verify(signature: signature, message: message, address: "0x15bca56b6e2728aec2532df9d436bd1600e86688", chainId: "eip155:1")
    }
}
