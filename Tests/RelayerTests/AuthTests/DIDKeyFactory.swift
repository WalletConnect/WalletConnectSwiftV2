import Foundation
import XCTest
@testable import WalletConnectUtils
@testable import WalletConnectRelay

final class DIDKeyFactoryTests: XCTestCase {

    let expectedEDDidWithPrefix = "did:key:z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
    let expectedEDDidWithoutPrefix = "z6MkodHZwneVRShtaLf8JKYkxpDGp1vGZnpGmdBpX8M2exxH"
    let expectedXDidWithPrefix = "did:key:z6LSkrCgsrCvBMwAZECC9Q6sSJskqbBXrWk4xazaBK2YT7wf"
    let expectedXDidWithoutPrefix = "z6LSkrCgsrCvBMwAZECC9Q6sSJskqbBXrWk4xazaBK2YT7wf"

    let pubKey = Data(hex: "884ab67f787b69e534bfdba8d5beb4e719700e90ac06317ed177d49e5a33be5a")

    var sut: DIDKeyFactory!

    override func setUp() {
        sut = DIDKeyFactory()
    }

    func testEDKeyCreationWithoutPrefix() {
        let did = sut.make(pubKey: pubKey, variant: .ED25519, prefix: false)
        XCTAssertEqual(expectedEDDidWithoutPrefix, did)
    }

    func testEDKeyCreationWithPrefix() {
        let did = sut.make(pubKey: pubKey, variant: .ED25519, prefix: true)
        XCTAssertEqual(expectedEDDidWithPrefix, did)
    }

    func testXKeyCreationWithoutPrefix() {
        let did = sut.make(pubKey: pubKey, variant: .X25519, prefix: false)
        XCTAssertEqual(expectedXDidWithoutPrefix, did)
    }

    func testXKeyCreationWithPrefix() {
        let did = sut.make(pubKey: pubKey, variant: .X25519, prefix: true)
        XCTAssertEqual(expectedXDidWithPrefix, did)
    }
}
