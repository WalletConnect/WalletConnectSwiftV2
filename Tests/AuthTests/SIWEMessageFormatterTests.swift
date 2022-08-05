import Foundation
@testable import Auth
import XCTest

class SIWEMessageFormatterTests: XCTestCase {
    var sut: SIWEMessageFormatter!
    var expectedMessage =
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

    override func setUp() {
        sut = SIWEMessageFormatter()
    }

    func testFormatMessage() {
        let address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        let message = sut.formatMessage(from: AuthPayload.stub(), address: address)

        XCTAssertEqual(message, expectedMessage)
    }

    func testNilOptionalParamsMessage() {
        let address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

        let message = sut.formatMessage(from: AuthPayload(
            requestParams: RequestParams(
                domain: "domain",
                chainId: "chainId",
                nonce: "nonce",
                aud: "aud",
                nbf: nil, exp: nil, statement: nil, requestId: nil, resources: nil
            ),
            iat: "2021-09-30T16:25:24Z"
        ), address: address)

        XCTAssertEqual(message, "")
    }
}
