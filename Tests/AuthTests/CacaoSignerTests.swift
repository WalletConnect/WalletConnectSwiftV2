import Foundation
import XCTest
@testable import Auth
import TestingUtils

class CacaoSignerTest: XCTestCase {

    let privateKey = Data(hex: "8dcbe6f4abf0f558e1c87ad1ab864e9d0fa086dd997d7c7c22616c83728fea9c")

    let payload = CacaoPayload(
        iss: "did:pkh:eip155:1:0x22Fe071b3631f155F0d8f4c9377D3309cB904E10",
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

    let sig = CacaoSignature(t: "eip191", s: "ced1849ff778a1a55a9d5516c11f13d8637859c2af370b178e11e40fed5c239465c32db0e52849fc3638507090fc810f73a354c7a5c72f94ab9673db6085c20301", m: "")


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
