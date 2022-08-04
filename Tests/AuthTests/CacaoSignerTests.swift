import Foundation
import XCTest
@testable import Auth
import TestingUtils

class CacaoSignerTest: XCTestCase {

    let payload = CacaoPayload(
        iss: "did:pkh:eip155:1:0xBAc675C310721717Cd4A37F6cbeA1F081b1C2a07",
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

    let sig = CacaoSignature(t: "eip191", s: "11f3715374dbacdec7e51611c9f2a8f13c11d14fd62c9556fb87f09235b8acaa2b3cba50968180da3e8c902086430011229375545eec0264bb431708ae92713201", m: "")


    func testCacaoSign() async throws {
        let signer = CacaoSigner(signer: Signer(), keystore: MockCacaoKeystore())

        let signature = try await signer.sign(payload: payload)

        XCTAssertEqual(signature, sig)
    }

// TODO: Restore test
//    func testCacaoVerify() async throws {
//        let signer = CacaoSigner(signer: Signer(), keystore: MockCacaoKeystore())
//
//        try await signer.verify(signature: sig, payload: payload)
//    }
}

struct MockCacaoKeystore: CacaoSignerKeystore {

    var privateKey: Data {
        get async {
            return Data(hex: "8dcbe6f4abf0f558e1c87ad1ab864e9d0fa086dd997d7c7c22616c83728fea9c")
        }
    }
}
