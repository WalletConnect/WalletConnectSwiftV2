// 

import Foundation

import XCTest
@testable import WalletConnect_Swift

final class JSONRPCSerialiserTests: XCTestCase {
    var serialiser: JSONRPCSerialiser!
    var codec: MockedCodec!
    override func setUp() {
        codec = MockedCodec()
        self.serialiser = JSONRPCSerialiser(codec: codec)
    }
    
    override func tearDown() {
        serialiser = nil
    }
    
    func testSerialise() {
        codec.encryptionPayload = EncryptionPayload(iv: SerialiserTestData.iv,
                                                    publicKey: SerialiserTestData.publicKey,
                                                    mac: SerialiserTestData.mac,
                                                    cipherText: SerialiserTestData.cipherText)
        let agreementKeys = X25519AgreementKeys(sharedKey: Data(hex: ""), publicKey: Data(hex: ""))
        let serialisedMessage = try! serialiser.serialise(json: SerialiserTestData.pairingApproveJSON, agreementKeys: agreementKeys)
        let serialisedMessageSample = SerialiserTestData.serialisedMessage
        XCTAssertEqual(serialisedMessage, serialisedMessageSample)
    }
    
    func testDeserialise() {
        let serialisedMessageSample = SerialiserTestData.serialisedMessage
        codec.decodedJson = SerialiserTestData.pairingApproveJSON
        let deserialisedJSON = try! serialiser.deserialise(message: serialisedMessageSample, symmetricKey: Data(hex: ""))
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

