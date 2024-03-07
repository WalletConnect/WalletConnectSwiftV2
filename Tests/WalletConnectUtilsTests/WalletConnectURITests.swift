import XCTest
@testable import WalletConnectUtils

private func stubURI(includeMethods: Bool = true) -> (uri: WalletConnectURI, string: String) {
    let topic = Data.randomBytes(count: 32).toHexString()
    let symKey = Data.randomBytes(count: 32).toHexString()
    let protocolName = "irn"
    let timestamp = UInt64(Date().timeIntervalSince1970) + 5 * 60
    var uriString = "wc:\(topic)@2?symKey=\(symKey)&relay-protocol=\(protocolName)&expiryTimestamp=\(timestamp)"
    let methods = ["wc_sessionPropose", "wc_sessionAuthenticate"]
    if includeMethods {
        let methodsString = methods.joined(separator: ",")
        uriString.append("&methods=\(methodsString)")
    }
    let uri = WalletConnectURI(
        topic: topic,
        symKey: symKey,
        relay: RelayProtocolOptions(protocol: protocolName, data: nil),
        methods: includeMethods ? methods : nil)

    return (uri, uriString)
}

final class WalletConnectURITests: XCTestCase {

    // MARK: - Init URI with string

    func testInitURIToString() throws {
        let input = stubURI()
        let uriString = input.uri.absoluteString
        let outputURI = try WalletConnectURI(uriString: uriString)
        XCTAssertEqual(input.uri, outputURI)
        XCTAssertEqual(input.string, outputURI.absoluteString)
    }

    func testInitStringToURI() throws {
        let inputURIString = stubURI().string
        let uri = try WalletConnectURI(uriString: inputURIString)
        let outputURIString = uri.absoluteString
        XCTAssertEqual(inputURIString, outputURIString)
    }

    func testInitStringToURIAlternate() throws {
        let expectedString = stubURI().string
        let inputURIString = expectedString.replacingOccurrences(of: "wc:", with: "wc://")
        let uri = try WalletConnectURI(uriString: inputURIString)
        let outputURIString = uri.absoluteString
        XCTAssertEqual(expectedString, outputURIString)
    }

    // MARK: - Init URI failure cases

    func testInitFailsBadScheme() {
        let inputURIString = stubURI().string.replacingOccurrences(of: "wc:", with: "")
        XCTAssertThrowsError(try WalletConnectURI(uriString: inputURIString))
    }

    func testInitFailsMalformedURL() {
        let inputURIString = "wc://<"
        XCTAssertThrowsError(try WalletConnectURI(uriString: inputURIString))
    }

    func testInitFailsNoSymKeyParam() {
        let input = stubURI()
        let inputURIString = input.string.replacingOccurrences(of: "symKey=\(input.uri.symKey)", with: "")
        XCTAssertThrowsError(try WalletConnectURI(uriString: inputURIString))
    }

    func testInitFailsNoRelayParam() {
        let input = stubURI()
        let inputURIString = input.string.replacingOccurrences(of: "&relay-protocol=\(input.uri.relay.protocol)", with: "")
        XCTAssertThrowsError(try WalletConnectURI(uriString: inputURIString))
    }

    func testInitURIWithStringIncludingMethods() {
        let (expectedURI, uriStringWithMethods) = stubURI()
        guard let uri = WalletConnectURI(string: uriStringWithMethods) else {
            XCTFail("Initialization of URI failed")
            return
        }
        XCTAssertEqual(uri.methods, expectedURI.methods)
        XCTAssertEqual(uri.topic, expectedURI.topic)
        XCTAssertEqual(uri.symKey, expectedURI.symKey)
        XCTAssertEqual(uri.relay.protocol, expectedURI.relay.protocol)
        XCTAssertEqual(uri.absoluteString, expectedURI.absoluteString)
    }

    func testInitURIWithStringExcludingMethods() {
        let (expectedURI, uriStringWithoutMethods) = stubURI(includeMethods: false)
        guard let uri = WalletConnectURI(string: uriStringWithoutMethods) else {
            XCTFail("Initialization of URI failed")
            return
        }

        XCTAssertNil(uri.methods)
        XCTAssertEqual(uri.topic, expectedURI.topic)
        XCTAssertEqual(uri.symKey, expectedURI.symKey)
        XCTAssertEqual(uri.relay.protocol, expectedURI.relay.protocol)
        XCTAssertEqual(uri.absoluteString, expectedURI.absoluteString)
    }

    func testInitHandlesURLEncodedString() throws {
        let input = stubURI()
        let encodedURIString = input.string
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let uri = try WalletConnectURI(uriString: encodedURIString)

        // Assert that the initializer can handle encoded URI and it matches the expected URI
        XCTAssertEqual(input.uri, uri)
        XCTAssertEqual(input.string, uri.absoluteString)
    }

    // MARK: - Expiry Logic Tests

    func testExpiryTimestampIsSet() {
        let uri = stubURI().uri
        XCTAssertNotNil(uri.expiryTimestamp)
        XCTAssertTrue(uri.expiryTimestamp > UInt64(Date().timeIntervalSince1970))
    }

    func testInitFailsIfURIExpired() {
        let input = stubURI()
        // Create a URI string with an expired timestamp
        let expiredTimestamp = UInt64(Date().timeIntervalSince1970) - 300 // 5 minutes in the past
        let expiredURIString = "wc:\(input.uri.topic)@\(input.uri.version)?symKey=\(input.uri.symKey)&relay-protocol=\(input.uri.relay.protocol)&expiryTimestamp=\(expiredTimestamp)"
        XCTAssertThrowsError(try WalletConnectURI(uriString: expiredURIString))
    }

    // Test compatibility with old clients that don't include expiryTimestamp in their uri
    func testDefaultExpiryTimestampIfNotIncluded() throws {
        let input = stubURI().string
        // Remove expiryTimestamp from the URI string
        let uriStringWithoutExpiry = input.replacingOccurrences(of: "&expiryTimestamp=\(stubURI().uri.expiryTimestamp)", with: "")
        let uri = try WalletConnectURI(uriString: uriStringWithoutExpiry)

        // Check if the expiryTimestamp is set to 5 minutes in the future
        let expectedExpiryTimestamp = UInt64(Date().timeIntervalSince1970) + 5 * 60
        XCTAssertTrue(uri.expiryTimestamp >= expectedExpiryTimestamp)
    }

}
