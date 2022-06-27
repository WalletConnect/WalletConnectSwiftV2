import Foundation
import XCTest
@testable import WalletConnectRelay

final class Base58Tests: XCTestCase {

    private let validStringDecodedToEncodedTuples = [
        ("", ""),
        (" ", "Z"),
        ("-", "n"),
        ("0", "q"),
        ("1", "r"),
        ("-1", "4SU"),
        ("11", "4k8"),
        ("abc", "ZiCa"),
        ("1234598760", "3mJr7AoUXx2Wqd"),
        ("abcdefghijklmnopqrstuvwxyz", "3yxU3u1igY8WkgtjK92fbJQCd4BZiiT1v25f"),
        ("00000000000000000000000000000000000000000000000000000000000000",
         "3sN2THZeE9Eh9eYrwkvZqNstbHGvrxSAM7gXUXvyFQP8XvQLUqNCS27icwUeDT7ckHm4FUHM2mTVh1vbLmk7y")
    ]

    private let invalidStrings = [
        "0",
        "O",
        "I",
        "l",
        "3mJr0",
        "O3yxU",
        "3sNI",
        "4kl8",
        "0OIl",
        "!@#$%^&*()-_=+~`"
    ]

    func testBase58AddressDecoding() {
        let address = "FAKUpR8McSoHT1sTksfJu3L1SpRtHK91ocDYtop4A7HW"
        let result = Data(hex: "d266bd3d305bb45b5c12f8ff9b6315427e7a32a12c9f497c0c9c76cf5125278d")

        XCTAssertEqual(Base58.decode(address), result)
    }

    func testBase58EncodingForValidStrings() {
        for (decoded, encoded) in validStringDecodedToEncodedTuples {
            let data = Data(decoded.utf8)
            let result = Base58.encode(data)
            XCTAssertEqual(result, encoded)
        }
    }

    func testBase58DecodingForValidStrings() {
        for (decoded, encoded) in validStringDecodedToEncodedTuples {
            let data = Base58.decode(encoded)
            let result = String(data: data, encoding: String.Encoding.utf8)
            XCTAssertEqual(result, decoded)
        }
    }

    func testBase58DecodingForInvalidStrings() {
        for invalidString in invalidStrings {
            let result = Base58.decode(invalidString)
            XCTAssertEqual(result, Data())
        }
    }
}
