import XCTest
@testable import WalletConnectSign

final class AuthenticatedSessionRecapFactoryTests: XCTestCase {

    func testAuthenticatedSessionRecapFactory() {
        let recapUrn = try! AuthenticatedSessionRecapFactory.createNamespaceRecap(methods: ["personal_sign", "eth_sendTransaction"])
        let expectedUrn = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvcGVyc29uYWxfc2lnbiI6W10sInJlcXVlc3QvZXRoX3NlbmRUcmFuc2FjdGlvbiI6W119fX0="
        XCTAssertEqual(recapUrn, expectedUrn)
    }
}
