// 

import Foundation

import XCTest
@testable import WalletConnect_Swift

final class JSONRPCSerialiserTests: XCTestCase {
    var serialiser: JSONRPCSerialiser!
    
    override func setUp() {
        let codec = MockedCodec()
        codec.decodedJson = SerialiserTestData.pairingApproveJSON
        codec.encryptionPayload = EncryptionPayload(iv: SerialiserTestData.iv,
                                                    publicKey: SerialiserTestData.publicKey,
                                                    mac: SerialiserTestData.mac,
                                                    cipherText: SerialiserTestData.cipherText)
        self.serialiser = JSONRPCSerialiser(codec: codec)
    }
    
    override func tearDown() {
        serialiser = nil
    }
    
    func testSerialise() {
        let serialisedMessage = serialiser.serialise(json: SerialiserTestData.pairingApproveJSON, key: "")
        let serialisedMessageSample = SerialiserTestData.serialisedMessage
        XCTAssertEqual(serialisedMessage, serialisedMessageSample)
    }
    
    func testDeserialise() {
        let serialisedMessageSample = SerialiserTestData.serialisedMessage
        (serialiser.codec as! MockedCodec).decodedJson = SerialiserTestData.pairingApproveJSON
        let deserialisedJSON = try! serialiser.deserialise(message: serialisedMessageSample, key: "")
        XCTAssertEqual(deserialisedJSON.params, SerialiserTestData.pairingApproveJSONRPCRequest.params)
    }
    
    func testDeserialiseIntoPayload() {
        let payload = try! serialiser.deserialiseIntoPayload(message: SerialiserTestData.serialisedMessage)
        XCTAssertEqual(payload.iv, SerialiserTestData.iv)
        XCTAssertEqual(payload.publicKey, SerialiserTestData.publicKey)
        XCTAssertEqual(payload.mac, SerialiserTestData.mac)
        XCTAssertEqual(payload.cipherText, SerialiserTestData.cipherText)
    }
}

