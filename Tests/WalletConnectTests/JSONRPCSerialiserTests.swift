// 

import Foundation

import XCTest
@testable import WalletConnect

final class JSONRPCSerialiserTests: XCTestCase {
    var serialiser: JSONRPCSerialiser!
    var codec: MockedCodec!
    override func setUp() {
        codec = MockedCodec()
        self.serialiser = JSONRPCSerialiser(crypto: Crypto(keychain: KeychainStorageMock()), codec: codec)
    }
    
    override func tearDown() {
        serialiser = nil
    }
    
    func testSerialise() {
        codec.encryptionPayload = EncryptionPayload(iv: SerialiserTestData.iv,
                                                    publicKey: SerialiserTestData.publicKey,
                                                    mac: SerialiserTestData.mac,
                                                    cipherText: SerialiserTestData.cipherText)
        let serialisedMessage = try! serialiser.encrypt(json: SerialiserTestData.pairingApproveJSON, agreementKeys: SerialiserTestData.emptyAgreementSecret)
        let serialisedMessageSample = SerialiserTestData.serialisedMessage
        XCTAssertEqual(serialisedMessage, serialisedMessageSample)
    }
    
    func testDeserialise() {
        let serialisedMessageSample = SerialiserTestData.serialisedMessage
        codec.decodedJson = SerialiserTestData.pairingApproveJSON
        let deserialisedJSONRPC: WCRequest = try! serialiser.deserialise(message: serialisedMessageSample, symmetricKey: Data(hex: ""))
        XCTAssertEqual(deserialisedJSONRPC.params, SerialiserTestData.pairingApproveJSONRPCRequest.params)
    }
}

