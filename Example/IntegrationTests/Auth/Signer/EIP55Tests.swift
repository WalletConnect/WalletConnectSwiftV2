import Foundation
import XCTest
@testable import WalletConnectSigner

class EIP55Tests: XCTestCase {

    private let eip55 = EIP55(crypto: DefaultCryptoProvider())

    func testEIP55EncodingAllCaps() {
            let string1 = "0x52908400098527886E0F7030069857D2E4169EE7"
            let string2 = "0x8617E340B3D01FA5F11F306F4090FD50E238070D"

            XCTAssertEqual(eip55.encode(string1), "0x52908400098527886E0F7030069857D2E4169EE7")
            XCTAssertEqual(eip55.encode(string2), "0x8617E340B3D01FA5F11F306F4090FD50E238070D")
        }

        func testEIP55EncodingAllLower() {
            let string1 = "0x27b1fdb04752bbc536007a920d24acb045561c26"
            let string2 = "0xde709f2102306220921060314715629080e2fb77"

            XCTAssertEqual(eip55.encode(string1), "0x27b1fdb04752bbc536007a920d24acb045561c26")
            XCTAssertEqual(eip55.encode(string2), "0xde709f2102306220921060314715629080e2fb77")
        }

        func testEIP55EncodingNormal() {
            let string1 = "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"
            let string2 = "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359"
            let string3 = "0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb"
            let string4 = "0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb"

            XCTAssertEqual(eip55.encode(string1), "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed")
            XCTAssertEqual(eip55.encode(string2), "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")
            XCTAssertEqual(eip55.encode(string3), "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB")
            XCTAssertEqual(eip55.encode(string4), "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb")
        }

}
