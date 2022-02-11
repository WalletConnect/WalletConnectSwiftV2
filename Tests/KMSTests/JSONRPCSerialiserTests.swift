// 

import Foundation

import XCTest
@testable import KMS
@testable import TestingUtils

final class SerializerTests: XCTestCase {
    var serializer: Serializer!
    var codec: MockedCodec!
    override func setUp() {
        codec = MockedCodec()
        self.serializer = Serializer(crypto: KeyManagementService(keychain: KeychainStorageMock()), codec: codec)
    }
    
    override func tearDown() {
        serializer = nil
    }
    
//    func testSerialize() {
//        codec.encryptionPayload = EncryptionPayload(iv: SerializerTestData.iv,
//                                                    publicKey: SerializerTestData.publicKey,
//                                                    mac: SerializerTestData.mac,
//                                                    cipherText: SerializerTestData.cipherText)
//        let serializedMessage = try! serializer.encrypt(json: SerializerTestData.pairingApproveJSON, agreementKeys: SerializerTestData.emptyAgreementSecret)
//        let serializedMessageSample = SerializerTestData.serializedMessage
//        XCTAssertEqual(serializedMessage, serializedMessageSample)
//    }
//
//    func testDeserialize() {
//        let serializedMessageSample = SerializerTestData.serializedMessage
//        codec.decodedJson = SerializerTestData.pairingApproveJSON
//        let deserializedJSONRPC: WCRequest = try! serializer.deserialize(message: serializedMessageSample, symmetricKey: Data(hex: ""))
//        XCTAssertEqual(deserializedJSONRPC.params, SerializerTestData.pairingApproveJSONRPCRequest.params)
//    }
}

