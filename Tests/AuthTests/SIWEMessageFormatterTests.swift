import Foundation
@testable import Auth
import XCTest

class SIWEMessageFormatterTests: XCTestCase {
    var sut: SIWECacaoFormatter!
    let address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

    override func setUp() {
        sut = SIWECacaoFormatter()
    }

    func testFormatMessage() throws {
        let expectedMessage =
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
        let message = try sut.formatMessage(from: AuthPayload.stub().cacaoPayload(address: address))
        XCTAssertEqual(message, expectedMessage)
    }

    func testNilStatement() throws {
        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

            URI: https://service.invalid/login
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            Resources:
            - ipfs://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq/
            - https://example.com/my-web2-claim.json
            """
        let message = try sut.formatMessage(
            from: AuthPayload.stub(
                requestParams: RequestParams.stub(statement: nil)
            ).cacaoPayload(address: address)
        )
        XCTAssertEqual(message, expectedMessage)
    }

    func testNilResources() throws {
        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

            I accept the ServiceOrg Terms of Service: https://service.invalid/tos

            URI: https://service.invalid/login
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            """
        let message = try sut.formatMessage(
            from: AuthPayload.stub(
                requestParams: RequestParams.stub(resources: nil)).cacaoPayload(address: address)
            )
        XCTAssertEqual(message, expectedMessage)
    }

    func testNilAllOptionalParams() throws {
        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

            URI: https://service.invalid/login
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            """
        let message = try sut.formatMessage(
            from: AuthPayload.stub(
                requestParams: RequestParams.stub(statement: nil, resources: nil)).cacaoPayload(address: address)
        )
        XCTAssertEqual(message, expectedMessage)
    }
}
