import Foundation
import XCTest
@testable import WalletConnectRelay

final class ED25519DIDKeyFactoryTests: XCTestCase {
    let expectedDidWithPrefix = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
    let expectedDidWithoutPrefix = "z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
    let pubKey = Data(hex: "884ab67f787b69e534bfdba8d5beb4e719700e90ac06317ed177d49e5a33be5a")

    var sut: ED25519DIDKeyFactory!

    override func setUp() {
        sut = ED25519DIDKeyFactory()
    }

    func testKeyCreationWithoutPrefix() {
        let did = sut.make(pubKey: pubKey, prefix: false)
        XCTAssertEqual(expectedDidWithoutPrefix, did)
    }

    func testKeyCreationWithPrefix() {
        let did = sut.make(pubKey: pubKey, prefix: true)
        XCTAssertEqual(expectedDidWithPrefix, did)
    }
}
