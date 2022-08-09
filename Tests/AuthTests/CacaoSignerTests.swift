import Foundation
import XCTest
@testable import Auth
import TestingUtils

class CacaoSignerTest: XCTestCase {

    let privateKey = Data(hex: "305c6cde3846927892cd32762f6120539f3ec74c9e3a16b9b798b1e85351ae2a")

    let payload = CacaoPayload(
        iss: "did:pkh:eip155:1:0x15bca56b6e2728aec2532df9d436bd1600e86688",
        domain: "localhost:3000",
        aud: "http://localhost:3000/login",
        version: 1,
        nonce: "328917",
        iat: "2022-03-10T17:09:21.481+03:00",
        nbf: "2022-03-10T17:09:21.481+03:00",
        exp: "2022-03-10T18:09:21.481+03:00",
        statement: "I accept the ServiceOrg Terms of Service: https://service.org/tos",
        requestId: "request-id-random",
        resources: [
            "ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq",
            "https://example.com/my-web2-claim.json"
        ]
    )

    var cacao: Cacao {
        return Cacao(
            header: .init(t: ""),
            payload: payload,
            signature: sig
        )
    }

    let sig = CacaoSignature(t: "eip191", s: "914b8300e471744f506407aa072cdf9a606fd3fe1a6f2a16c9f78009074c69622143c3009f4ccdedc0fdd421e5579c5e11b3a604e0a3e6ae0cb06b5e380879fb00", m: "")

    func testCacaoSign() throws {
        let signer = CacaoSigner(signer: Signer())

        let signature = try signer.sign(payload: payload, privateKey: privateKey)

        XCTAssertEqual(signature, sig)
    }

    func testCacaoVerify() throws {
        let signer = CacaoSigner(signer: Signer())

        try signer.verifySignature(cacao)
    }
}
