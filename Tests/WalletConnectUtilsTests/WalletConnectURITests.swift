import XCTest
@testable import WalletConnectUtils

private func stubURI(api: WalletConnectURI.TargetAPI? = nil) -> (uri: WalletConnectURI, string: String) {
    let topic = Data.randomBytes(count: 32).toHexString()
    let symKey = Data.randomBytes(count: 32).toHexString()
    let protocolName = "irn"
    let uriBase = api == nil ? "wc:" : "wc:\(api!.rawValue)-"
    let uriString = "\(uriBase)\(topic)@2?symKey=\(symKey)&relay-protocol=\(protocolName)"
    let uri = WalletConnectURI(
        topic: topic,
        symKey: symKey,
        relay: RelayProtocolOptions(protocol: protocolName, data: nil),
        api: api)
    return (uri, uriString)
}

final class WalletConnectURITests: XCTestCase {

    // MARK: - Init URI with string

    func testInitURIToString() {
        let input = stubURI()
        let uriString = input.uri.absoluteString
        let outputURI = WalletConnectURI(string: uriString)
        XCTAssertEqual(input.uri, outputURI)
        XCTAssertEqual(input.string, outputURI?.absoluteString)
    }

    func testInitStringToURI() {
        let inputURIString = stubURI().string
        let uri = WalletConnectURI(string: inputURIString)
        let outputURIString = uri?.absoluteString
        XCTAssertEqual(inputURIString, outputURIString)
    }

    func testInitStringToURIAlternate() {
        let expectedString = stubURI().string
        let inputURIString = expectedString.replacingOccurrences(of: "wc:", with: "wc://")
        let uri = WalletConnectURI(string: inputURIString)
        let outputURIString = uri?.absoluteString
        XCTAssertEqual(expectedString, outputURIString)
    }

    // MARK: - Init URI with prefix API identifier

    func testInitFromPrefixedURIString() {
        WalletConnectURI.TargetAPI.allCases.forEach { api in
            let uriString = stubURI(api: api).string
            let uri = WalletConnectURI(string: uriString)
            XCTAssertEqual(uri?.api, api)
            XCTAssertEqual(uri?.absoluteString, uriString)
        }
    }

    func testAbsentPrefixFallbackToSign() {
        let input = stubURI()
        let uriFromParams = input.uri
        let uriFromString = WalletConnectURI(string: input.string)
        XCTAssertEqual(uriFromParams.api, .sign)
        XCTAssertEqual(uriFromString?.api, .sign)
    }

    // MARK: - Init URI failure cases

    func testInitFailsBadScheme() {
        let inputURIString = stubURI().string.replacingOccurrences(of: "wc:", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }

    func testInitFailsMalformedURL() {
        let inputURIString = "wc://<"
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }

    func testInitFailsNoSymKeyParam() {
        let input = stubURI()
        let inputURIString = input.string.replacingOccurrences(of: "symKey=\(input.uri.symKey)", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }

    func testInitFailsNoRelayParam() {
        let input = stubURI()
        let inputURIString = input.string.replacingOccurrences(of: "&relay-protocol=\(input.uri.relay.protocol)", with: "")
        let uri = WalletConnectURI(string: inputURIString)
        XCTAssertNil(uri)
    }
}
