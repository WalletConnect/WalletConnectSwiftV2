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
        var codec = MockedCodec()
        codec.decodedJson = json
        codec.encryptionPayload = EncryptionPayload(iv: HexString(SerialiserTestsSamples.iv),
                                                    publicKey: HexString(SerialiserTestsSamples.publicKey),
                                                    mac: HexString(SerialiserTestsSamples.mac),
                                                    cipherText: HexString(SerialiserTestsSamples.cipherText))
        self.serialiser = JSONRPCSerialiser(codec: codec)
    }
    
    override func tearDown() {
        serialiser = nil
    }
    
    func testSerialise() {
        let serialisedMessage = serialiser.serialise(json: json, key: "")
        let serialisedMessageSample = SerialiserTestsSamples.serialisedMessage
        XCTAssertEqual(serialisedMessage, serialisedMessageSample)
    }
    
    func testDeserialise() {
        let serialisedMessageSample = SerialiserTestsSamples.serialisedMessage
        let deserialisedJSON = try! serialiser.deserialise(message: serialisedMessageSample, key: "")
        XCTFail("not implemented")
    }
    
    func testDeserialiseIntoPayload() {
        let payload = try! serialiser.deserialiseIntoPayload(message: SerialiserTestsSamples.serialisedMessage)
        XCTAssertEqual(payload.iv.string, SerialiserTestsSamples.iv)
        XCTAssertEqual(payload.publicKey.string, SerialiserTestsSamples.publicKey)
        XCTAssertEqual(payload.mac.string, SerialiserTestsSamples.mac)
        XCTAssertEqual(payload.cipherText.string, SerialiserTestsSamples.cipherText)
    }
}

