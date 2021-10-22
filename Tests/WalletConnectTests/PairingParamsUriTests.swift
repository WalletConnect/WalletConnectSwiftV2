import XCTest
@testable import WalletConnect

final class PairingParamsUriTests: XCTestCase {
    func testInitFromUriAndConvertToUri() {
        let uriParameters = PairingType.UriParameters(stubURI)!
        let uriConverted = uriParameters.absoluteString()!
        XCTAssertEqual(stubURI, uriConverted)
    }
}

fileprivate let stubURI = "wc:8097df5f14871126866252c1b7479a14aefb980188fc35ec97d130d24bd887c8@2?controller=false&publicKey=19c5ecc857963976fabb98ed6a3e0a6ab6b0d65c018b6e25fbdcd3a164def868&relay=%7B%22protocol%22%3A%22waku%22%7D"

final class WalletConnectURITests: XCTestCase {
    
    func testInitURIToString() {
        let inputURI = WalletConnectURI(
            topic: "8097df5f14871126866252c1b7479a14aefb980188fc35ec97d130d24bd887c8",
            publicKey: "19c5ecc857963976fabb98ed6a3e0a6ab6b0d65c018b6e25fbdcd3a164def868",
            isController: true,
            relay: RelayProtocolOptions(protocol: "waku", params: nil))
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
}
