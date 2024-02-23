import XCTest
@testable import WalletConnectSign

final class AuthenticatedSessionRecapFactoryTests: XCTestCase {

    func testAuthenticatedSessionRecapFactory() {
        // {"att":{"eip155":{"request/eth_sendTransaction":[{}],"request/personal_sign":[{}]}}}
        let recapUrn1 = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvZXRoX3NlbmRUcmFuc2FjdGlvbiI6W3t9XSwicmVxdWVzdC9wZXJzb25hbF9zaWduIjpbe31dfX19"


        //{"att":{"eip155":{"request/personal_sign":[{}],"request/eth_sendTransaction":[{}]}}}
        let recapUrn2 = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvcGVyc29uYWxfc2lnbiI6W3t9XSwicmVxdWVzdC9ldGhfc2VuZFRyYW5zYWN0aW9uIjpbe31dfX19"

        let recapUrn = try! AuthenticatedSessionRecapUrnFactory.createNamespaceRecap(methods: ["personal_sign", "eth_sendTransaction"])

        let urns = [recapUrn1, recapUrn2]

        XCTAssertTrue(urns.contains(recapUrn))
    }
}
