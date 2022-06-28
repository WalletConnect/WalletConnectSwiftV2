import Foundation
import XCTest
@testable import WalletConnectRelay

final class ED25519DIDKeyFactoryTests: XCTestCase {
    let expectedDid = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
    let pubKey = Data(hex: "884ab67f787b69e534bfdba8d5beb4e719700e90ac06317ed177d49e5a33be5a")

    var sut: ED25519DIDKeyFactory!

    override func setUp() {
        sut = ED25519DIDKeyFactory()
    }

    func testKeyCreation() {
        let did = sut.make(pubKey: pubKey)
        XCTAssertEqual(expectedDid, did)
    }
}
