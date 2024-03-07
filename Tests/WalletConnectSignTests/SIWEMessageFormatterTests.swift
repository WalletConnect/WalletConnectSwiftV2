import Foundation
@testable import WalletConnectUtils
@testable import WalletConnectSign
import XCTest

class SIWEMessageFormatterTests: XCTestCase {
    var sut: SIWECacaoFormatter!
    let address = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

    override func setUp() {
        sut = SIWECacaoFormatter()
    }

    func testFormatMessage() throws {
        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

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
        let message = try sut.formatMessage(from: AuthPayload.stub().cacaoPayload(account: Account.stub()))
        XCTAssertEqual(message, expectedMessage)
    }

    func testNilStatement() throws {
        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2


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
                requestParams: AuthRequestParams.stub(statement: nil)
            ).cacaoPayload(account: Account.stub())
        )
        XCTAssertEqual(message, expectedMessage)
    }

    func testNilResources() throws {
        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

            I accept the ServiceOrg Terms of Service: https://service.invalid/tos

            URI: https://service.invalid/login
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            """
        let message = try sut.formatMessage(
            from: AuthPayload.stub(
                requestParams: AuthRequestParams.stub(resources: nil)).cacaoPayload(account: Account.stub())
            )
        XCTAssertEqual(message, expectedMessage)
    }

    func testNilAllOptionalParams() throws {
        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

            
            URI: https://service.invalid/login
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            """
        let message = try sut.formatMessage(
            from: AuthPayload.stub(
                requestParams: AuthRequestParams.stub(statement: nil, resources: nil)).cacaoPayload(account: Account.stub())
        )
        XCTAssertEqual(message, expectedMessage)
    }

    func testWithValidRecapAndStatement() throws {
        let validRecapUrn = "urn:recap:eyJhdHQiOiB7ImVpcDE1NSI6IHsicmVxdWVzdC9ldGhfc2VuZFRyYW5zYWN0aW9uIjogW10sICJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOiBbXX19fQ=="

        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

            I accept the ServiceOrg Terms of Service: https://service.invalid/tos I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'.

            URI: https://service.invalid/login
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            Resources:
            - urn:recap:eyJhdHQiOiB7ImVpcDE1NSI6IHsicmVxdWVzdC9ldGhfc2VuZFRyYW5zYWN0aW9uIjogW10sICJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOiBbXX19fQ==
            """



        let payload = try AuthPayload.stub(
            requestParams: AuthRequestParams.stub(resources: [validRecapUrn])
        ).cacaoPayload(account: Account.stub())

        let message = try sut.formatMessage(from: payload, includeRecapInTheStatement: true)
        XCTAssertEqual(message, expectedMessage)
    }

    func testWithValidRecapAndNoStatement() throws {
        let validRecapUrn = "urn:recap:eyJhdHQiOiB7ImVpcDE1NSI6IHsicmVxdWVzdC9ldGhfc2VuZFRyYW5zYWN0aW9uIjogW10sICJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOiBbXX19fQ=="

        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

            I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'.

            URI: https://service.invalid/login
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            Resources:
            - urn:recap:eyJhdHQiOiB7ImVpcDE1NSI6IHsicmVxdWVzdC9ldGhfc2VuZFRyYW5zYWN0aW9uIjogW10sICJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOiBbXX19fQ==
            """


        let payload = try AuthPayload.stub(
            requestParams: AuthRequestParams.stub(statement: nil,resources: [validRecapUrn])
        ).cacaoPayload(account: Account.stub())

        let message = try sut.formatMessage(from: payload, includeRecapInTheStatement: true)
        XCTAssertEqual(message, expectedMessage)
    }

    func testWithSignAndNotifyRecaps() throws {
        let recap1 = "urn:recap:ewogICAiYXR0Ijp7CiAgICAgICJlaXAxNTUiOnsKICAgICAgICAgInJlcXVlc3QvZXRoX3NlbmRUcmFuc2FjdGlvbiI6IFt7fV0sCiAgICAgICAgICJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOiBbe31dCiAgICAgIH0KICAgfQp9"

        let recap2 = "urn:recap:ewogICAiYXR0Ijp7CiAgICAgICJodHRwczovL25vdGlmeS53YWxsZXRjb25uZWN0LmNvbS9hbGwtYXBwcyI6ewogICAgICAgICAiY3J1ZC9ub3RpZmljYXRpb25zIjogW3t9XSwKICAgICAgICAgImNydWQvc3Vic2NyaXB0aW9ucyI6IFt7fV0KICAgICAgfQogICB9Cn0="

        let expectedMessage =
            """
            service.invalid wants you to sign in with your Ethereum account:
            0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2

            I further authorize the stated URI to perform the following actions on my behalf: (1) 'request': 'eth_sendTransaction', 'personal_sign' for 'eip155'. (2) 'crud': 'notifications', 'subscriptions' for 'https://notify.walletconnect.com/all-apps'.

            URI: https://service.invalid?walletconnect_notify_key=did:key:z6MktW4hKdsvcXgt9wXmYbSD5sH4NCk5GmNZnokP9yh2TeCf
            Version: 1
            Chain ID: 1
            Nonce: 32891756
            Issued At: 2021-09-30T16:25:24Z
            Resources:
            - urn:recap:ewogICAiYXR0Ijp7CiAgICAgICJlaXAxNTUiOnsKICAgICAgICAgInJlcXVlc3QvZXRoX3NlbmRUcmFuc2FjdGlvbiI6IFt7fV0sCiAgICAgICAgICJyZXF1ZXN0L3BlcnNvbmFsX3NpZ24iOiBbe31dCiAgICAgIH0KICAgfQp9
            - urn:recap:ewogICAiYXR0Ijp7CiAgICAgICJodHRwczovL25vdGlmeS53YWxsZXRjb25uZWN0LmNvbS9hbGwtYXBwcyI6ewogICAgICAgICAiY3J1ZC9ub3RpZmljYXRpb25zIjogW3t9XSwKICAgICAgICAgImNydWQvc3Vic2NyaXB0aW9ucyI6IFt7fV0KICAgICAgfQogICB9Cn0=
            """


        let uri = "https://service.invalid?walletconnect_notify_key=did:key:z6MktW4hKdsvcXgt9wXmYbSD5sH4NCk5GmNZnokP9yh2TeCf"
        let payload = try AuthPayload.stub(
            requestParams: AuthRequestParams.stub(uri: uri, statement: nil,resources: [recap1, recap2])
        ).cacaoPayload(account: Account.stub())

        let message = try sut.formatMessage(from: payload, includeRecapInTheStatement: true)
        XCTAssertEqual(message, expectedMessage)
    }
}
