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

    let sig = CacaoSignature(t: "eip191", s: "5ccb134ad3d874cbb40a32b399549cd32c953dc5dc87dc64624a3e3dc0684d7d4833043dd7e9f4a6894853f8dc555f97bc7e3c7dd3fcc66409eb982bff3a44671b", m: "")


    func testCacaoSign() async throws {
        let signer = CacaoSigner(signer: Signer(), keystore: MockCacaoKeystore())

        let signature = try await signer.sign(payload: payload)

        XCTAssertEqual(signature, CacaoSignature(t: "eip191", s: "8ed4211b12ff15435b6735ee58b027294ebb5ebf7b5bd82224b4499fdbc11427c4432851d0e11f43f81df179f675bdc6d1db12ea6f53bd86058a6e9088c7c17a00", m: ""))
    }

    func testCacaoVerify() async throws {
        let signer = CacaoSigner(signer: Signer(), keystore: MockCacaoKeystore())

        await XCTAssertNoThrowAsync(try await signer.verify(signature: sig, payload: payload))
    }
}

struct MockCacaoKeystore: CacaoSignerKeystore {

    var privateKey: Data {
        get async {
            return Data(base64Encoded: "jcvm9Kvw9VjhyHrRq4ZOnQ+ght2ZfXx8ImFsg3KP6pw=")!
        }
    }
}
