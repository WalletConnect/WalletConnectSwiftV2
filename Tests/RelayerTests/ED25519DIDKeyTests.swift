import Foundation
import XCTest
@testable import WalletConnectRelay

final class ED25519DIDKeyTests: XCTestCase {
    let expectedDid = ""
    var sut: ED25519DIDKey!


    func test() {
        let pubKey = Data(hex: "884ab67f787b69e534bfdba8d5beb4e719700e90ac06317ed177d49e5a33be5a")
        let didKey = sut.make(pubKey: pubKey)
        XCTAssertEqual(didKey, expectedDid)
    }

}
