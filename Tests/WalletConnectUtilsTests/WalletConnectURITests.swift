import XCTest
@testable import WalletConnectUtils

private let stubTopic = "8097df5f14871126866252c1b7479a14aefb980188fc35ec97d130d24bd887c8"
private let stubSymKey = "587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303"
private let stubProtocol = "irn"

private let stubURI = "wc:auth-\(stubTopic)@2?symKey=\(stubSymKey)&relay-protocol=\(stubProtocol)"

final class WalletConnectURITests: XCTestCase {

    func testInitURIToString() {
        let inputURI = WalletConnectURI(
            topic: "8097df5f14871126866252c1b7479a14aefb980188fc35ec97d130d24bd887c8",
            symKey: "19c5ecc857963976fabb98ed6a3e0a6ab6b0d65c018b6e25fbdcd3a164def868",
            relay: RelayProtocolOptions(protocol: "irn", data: nil))
        let uriString = inputURI.absoluteString
        let outputURI = WalletConnectURI(string: uriString)
        XCTAssertEqual(inputURI, outputURI)
    }

    func testInitStringToURI() {
        let inputURIString = stubURI
        let uri = WalletConnectURI(string: inputURIString)
        let outputURIString = uri?.absoluteString
        XCTAssertEqual(inputURIString, outputURIString)
    }

    func testInitStringToURIAlternate() {
        let expectedString = stubURI
        let inputURIString = expectedString.replacingOccurrences(of: "wc:", with: "wc://")
        let uri = WalletConnectURI(string: inputURIString)
        let outputURIString = uri?.absoluteString
        XCTAssertEqual(expectedString, outputURIString)
    }

    // MARK: - Init failure cases

    func testInitFailsBadScheme() {
        let inputURIString = stubURI.replacingOccurrences(of: "wc:", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }

    func testInitFailsMalformedURL() {
        let inputURIString = "wc://<"
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }

    func testInitFailsNoSymKeyParam() {
        let inputURIString = stubURI.replacingOccurrences(of: "symKey=\(stubSymKey)", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }

    func testInitFailsNoRelayParam() {
        let inputURIString = stubURI.replacingOccurrences(of: "&relay-protocol=\(stubProtocol)", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }
}
