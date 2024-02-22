import XCTest
@testable import WalletConnectSign

final class AuthenticatedSessionRecapFactoryTests: XCTestCase {

    func testAuthenticatedSessionRecapFactory() {
        // {"att":{"eip155":{"request/eth_sendTransaction":[{}],"request/personal_sign":[{}]}}}
        let referenceRecap = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvZXRoX3NlbmRUcmFuc2FjdGlvbiI6W3t9XSwicmVxdWVzdC9wZXJzb25hbF9zaWduIjpbe31dfX19"

        let recapUrn = try! AuthenticatedSessionRecapUrnFactory.createNamespaceRecap(methods: ["personal_sign", "eth_sendTransaction"])

        XCTAssertEqual(recapUrn, referenceRecap)
    }
}
