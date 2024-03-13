import Foundation
import XCTest
@testable import WalletConnectUtils
@testable import WalletConnectSigner
@testable import WalletConnectSign


class CacaoSignerTest: XCTestCase {

    let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory())
        .create()
    let verifier = MessageVerifierFactory(crypto: DefaultCryptoProvider()).create(projectId: InputConfig.projectId)

    let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")

    let message: String =
        """
        service.invalid wants you to sign in with your Ethereum account:
        0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

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

    let payload = try! AuthPayload(requestParams: AuthRequestParams(
        domain: "service.invalid",
        chains: ["eip155:1"],
        nonce: "32891756",
        uri: "https://service.invalid/login",
        nbf: nil,
        exp: nil,
        statement: "I accept the ServiceOrg Terms of Service: https://service.invalid/tos",
        requestId: nil,
        resources: [
            "ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/",
            "https://example.com/my-web2-claim.json"
        ],
        methods: nil
    ), iat: "2021-09-30T16:25:24Z")

    let signature = CacaoSignature(t: .eip191, s: "0x2755a5cf4542e8649fadcfca8c983068ef3bda6057550ecd1ead32b75125a4547ed8e91ef76ef17e969434ffa4ac2e4dc1e8cd8be55d342ad9e223c64fbfe1dd1b")

    func testCacaoSign() throws {
        let account = Account("eip155:1:0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")!
        let cacaoPayload = try CacaoPayloadBuilder.makeCacaoPayload(authPayload: payload, account: account)
        let formatted = try SIWEFromCacaoPayloadFormatter().formatMessage(from: cacaoPayload)
        XCTAssertEqual(formatted, message)
        XCTAssertEqual(try signer.sign(payload: cacaoPayload, privateKey: privateKey, type: .eip191), signature)
    }

    func testCacaoVerify() async throws {
        try await verifier.verify(signature: signature, message: message, address: "0x15bca56b6e2728aec2532df9d436bd1600e86688", chainId: "eip155:1")
    }
}
