// 

import Foundation

import XCTest
@testable import WalletConnect_Swift

final class JSONRPCSerialiserTests: XCTestCase {
    var serialiser: JSONRPCSerialiser!
    private let json = """
    {
        "key": "value"
    }
    """
    
    override func setUp() {
        let codec = AES_256_CBC_HMAC_SHA256_Codec()
        self.serialiser = JSONRPCSerialiser(codec: codec)
    }
    
    override func tearDown() {
        serialiser = nil
    }
    
    func testDeserialisedMatchesOriginal() {
        let serialisedMessage = serialiser.serialise(json: json)
        let deserialisedString = serialiser.deserialise(message: serialisedMessage)
        XCTAssertEqual(deserialisedString, json, "deserialised message does not match original string")
    }
}
