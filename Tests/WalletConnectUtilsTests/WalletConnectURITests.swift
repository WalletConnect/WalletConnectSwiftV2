import XCTest
@testable import WalletConnectUtils

final class WalletConnectURITests: XCTestCase {

    var stubURI: String!

    var stubTopic: String!
    var stubSymKey: String!
    let stubProtocol = "irn"

    override func setUp() {
        let topic = Data.randomBytes(count: 32).toHexString()
        let symKey = Data.randomBytes(count: 32).toHexString()
        stubTopic = topic
        stubSymKey = symKey
        stubURI = "wc:\(topic)@2?symKey=\(symKey)&relay-protocol=\(stubProtocol)"
    }

    override func tearDown() {
        stubURI = nil
        stubTopic = nil
        stubSymKey = nil
    }

    func testInitURIToString() {
        let inputURI = WalletConnectURI(
            topic: stubTopic,
            symKey: stubSymKey,
            relay: RelayProtocolOptions(protocol: stubProtocol, data: nil))
        let uriString = inputURI.absoluteString
        let outputURI = WalletConnectURI(string: uriString)
        XCTAssertEqual(inputURI, outputURI)
        XCTAssertEqual(stubURI, outputURI?.absoluteString)
    }

    func testInitStringToURI() {
        let inputURIString = stubURI!
        let uri = WalletConnectURI(string: inputURIString)
        let outputURIString = uri?.absoluteString
        XCTAssertEqual(inputURIString, outputURIString)
    }

    func testInitStringToURIAlternate() {
        let expectedString = stubURI!
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
        let symKey = stubSymKey!
        let inputURIString = stubURI.replacingOccurrences(of: "symKey=\(symKey)", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }

    func testInitFailsNoRelayParam() {
        let inputURIString = stubURI.replacingOccurrences(of: "&relay-protocol=\(stubProtocol)", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }
}
