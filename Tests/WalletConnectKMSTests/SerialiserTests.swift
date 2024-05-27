import Foundation
import XCTest
@testable import WalletConnectKMS
@testable import TestingUtils

final class SerializerTests: XCTestCase {
    var mySerializer: Serializer!
    var myKms: KeyManagementServiceProtocol!

    var peerSerializer: Serializer!
    var peerKms: KeyManagementServiceProtocol!

    override func setUp() {
        self.myKms = KeyManagementServiceMock()
        self.mySerializer = Serializer(kms: myKms, logger: ConsoleLoggerMock())

        self.peerKms = KeyManagementServiceMock()
        self.peerSerializer = Serializer(kms: peerKms, logger: ConsoleLoggerMock())
    }

    func testSerializeDeserializeType0Envelope() {
        let topic = TopicGenerator().topic
        _ = try! myKms.createSymmetricKey(topic)
        let messageToSerialize = "todo - change for request object"
        let serializedMessage = try! mySerializer.serialize(topic: topic, encodable: messageToSerialize, envelopeType: .type0)
        let (deserializedMessage, _, _): (String, String?, Data) = mySerializer.tryDeserialize(topic: topic, codingType: .base64Encoded, envelopeString: serializedMessage)!
        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }

    func testSerializeDeserializeType1Envelope() {
        let myPubKey = try! myKms.createX25519KeyPair()
        let topic = myPubKey.rawRepresentation.sha256().toHexString()
        try! myKms.setPublicKey(publicKey: myPubKey, for: topic)
        // ----------------Peer Serialising------------------
        let messageToSerialize = "todo - change for request object"
        let peerPubKey = try! peerKms.createX25519KeyPair()
        let agreementKeys = try! peerKms.performKeyAgreement(selfPublicKey: peerPubKey, peerPublicKey: myPubKey.hexRepresentation)
        try! peerKms.setAgreementSecret(agreementKeys, topic: topic)
        let serializedMessage = try! peerSerializer.serialize(topic: topic, encodable: messageToSerialize, envelopeType: .type1(pubKey: peerPubKey.rawRepresentation))
        print(agreementKeys.sharedKey.hexRepresentation)
        // -----------Me Deserialising -------------------
        let (deserializedMessage, _, _): (String, String?, Data) = mySerializer.tryDeserialize(topic: topic, codingType: .base64Encoded, envelopeString: serializedMessage)!
        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }

    func testSerializeDeserializeType2Envelope() {

        let messageToSerialize = "todo - change for request object"

        // Serialize the sample object with Type 2 envelope
        guard let serializedMessage = try? mySerializer.serialize(topic: "", encodable: messageToSerialize, envelopeType: .type2) else {
            XCTFail("Serialization failed for Type 2 envelope.")
            return
        }

        // Deserialize the serialized message back into the original object
        guard let (deserializedMessage, _, _): (String, String?, Data) = mySerializer.tryDeserialize(topic: "", codingType: .base64UrlEncoded, envelopeString: serializedMessage) else {
            XCTFail("Deserialization failed for Type 2 envelope.")
            return
        }

        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }

    func testDeserializeRequestSuccessfully() {
        // Using a dictionary as params to adhere to the non-primitive requirement
        struct TestType: Codable {
            let string: String
        }
        let testType = TestType(string: "")
        let anyCodableParams = AnyCodable(testType)

        let request = RPCRequest(method: "testMethod", params: anyCodableParams, id: 123)
        let topic = TopicGenerator().topic
        _ = try! myKms.createSymmetricKey(topic)
        let serialized = try! mySerializer.serialize(topic: topic, encodable: request, envelopeType: .type0)

        if let result = mySerializer.tryDeserializeRequestOrResponse(topic: topic, codingType: .base64Encoded, envelopeString: serialized) {
            switch result {
            case .left(let result):
                XCTAssertEqual(result.request.method, request.method)
                XCTAssertEqual(result.request.id, request.id)
                // You'll need to compare the params more thoroughly in practice.
            default:
                XCTFail("Deserialization should have succeeded with RPCRequest")
            }
        } else {
            XCTFail("Deserialization failed")
        }
    }


    func testDeserializeResponseSuccessfully() {
        let response = RPCResponse(id: 123, result: "testResult")
        let topic = TopicGenerator().topic
        _ = try! myKms.createSymmetricKey(topic)
        let serialized = try! mySerializer.serialize(topic: topic, encodable: response, envelopeType: .type0)

        if let result = mySerializer.tryDeserializeRequestOrResponse(topic: topic, codingType: .base64Encoded, envelopeString: serialized) {
            switch result {
            case .right(let result):
                XCTAssertEqual(result.response, response)
            default:
                XCTFail("Deserialization should have succeeded with RPCResponse")
            }
        } else {
            XCTFail("Deserialization failed")
        }
    }

    func testDeserializeFailure() {
        let invalidData = "invalidData"
        let topic = TopicGenerator().topic
        _ = try! myKms.createSymmetricKey(topic)
        // Assuming serialize can accept invalidData for the purpose of this test
        let serialized = try! mySerializer.serialize(topic: topic, encodable: invalidData, envelopeType: .type0)

        let result = mySerializer.tryDeserializeRequestOrResponse(topic: topic, codingType: .base64Encoded, envelopeString: serialized)
        XCTAssertNil(result, "Deserialization should fail for invalid data")
    }

}
