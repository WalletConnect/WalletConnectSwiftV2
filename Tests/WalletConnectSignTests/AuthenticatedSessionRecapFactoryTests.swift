import XCTest
@testable import WalletConnectSign

final class AuthenticatedSessionRecapFactoryTests: XCTestCase {

    func testAuthenticatedSessionRecapFactory() {
        // {"att":{"eip155":{"request/eth_sendTransaction":[],"request/personal_sign":[]}}}
        let recapUrn1 = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvZXRoX3NlbmRUcmFuc2FjdGlvbiI6W10sInJlcXVlc3QvcGVyc29uYWxfc2lnbiI6W119fX0="

        // {"att":{"eip155":{"request/personal_sign":[],"request/eth_sendTransaction":[]}}}
        let recapUrn2 = "urn:recap:eyJhdHQiOnsiZWlwMTU1Ijp7InJlcXVlc3QvcGVyc29uYWxfc2lnbiI6W10sInJlcXVlc3QvZXRoX3NlbmRUcmFuc2FjdGlvbiI6W119fX0="

        let urns = [recapUrn1, recapUrn2]
        let recapUrn = try! AuthenticatedSessionRecapUrnFactory.createNamespaceRecap(methods: ["personal_sign", "eth_sendTransaction"])

        XCTAssertTrue(urns.contains(recapUrn))
    }
}
