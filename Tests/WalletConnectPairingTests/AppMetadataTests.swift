import XCTest
@testable import WalletConnectPairing

final class RedirectTests: XCTestCase {

    func testInitThrowsErrorWhenLinkModeIsTrueAndUniversalIsNil() {
        XCTAssertThrowsError(try AppMetadata.Redirect(native: "nativeURL", universal: nil, linkMode: true)) { error in
            XCTAssertEqual(error as? AppMetadata.Redirect.Errors, .invalidLinkModeUniversalLink)
        }
    }

    func testInitThrowsErrorWhenUniversalIsInvalidURL() {
        XCTAssertThrowsError(try AppMetadata.Redirect(native: "nativeURL", universal: "invalid-url", linkMode: false)) { error in
            XCTAssertEqual(error as? AppMetadata.Redirect.Errors, .invalidUniversalLinkURL)
        }
    }

    func testInitSucceedsWhenUniversalIsValidURLAndLinkModeIsTrue() {
        XCTAssertNoThrow(try AppMetadata.Redirect(native: "nativeURL", universal: "https://valid.url", linkMode: true))
    }

    func testInitSucceedsWhenUniversalIsValidURLAndLinkModeIsFalse() {
        XCTAssertNoThrow(try AppMetadata.Redirect(native: "nativeURL", universal: "https://valid.url", linkMode: false))
    }

    func testInitSucceedsWhenUniversalIsValidURLWithWWWAndLinkModeIsFalse() {
        XCTAssertNoThrow(try AppMetadata.Redirect(native: "nativeURL", universal: "www.valid.com", linkMode: false))
    }

    func testInitSucceedsWhenLinkModeIsFalseAndUniversalIsNil() {
        XCTAssertNoThrow(try AppMetadata.Redirect(native: "nativeURL", universal: nil, linkMode: false))
    }
}
