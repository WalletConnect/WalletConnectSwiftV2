// 

import Foundation
import XCTest
@testable import WalletConnectKMS
@testable import TestingUtils

final class SerializerTests: XCTestCase {
    var serializer: Serializer!
    var kms: KeyManagementServiceProtocol!
    
    override func setUp() {
        self.kms = KeyManagementServiceMock()
        self.serializer = Serializer(kms: kms)
    }
    
    override func tearDown() {
        serializer = nil
    }
    
    func testSerializeDeserializeType0Envelope() {
        let topic = TopicGenerator().topic
        _ = try! kms.createSymmetricKey(topic)
        let messageToSerialize = "todo - change for request object"
        let serializedMessage = try! serializer.serialize(topic: topic, encodable: messageToSerialize, envelopeType: .type0)
        let deserializedMessage: String? = serializer.tryDeserialize(topic: topic, encodedEnvelope: serializedMessage)
        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }

//    func testSerializeDeserializeType1Envelope() {
//        let topic = TopicGenerator().topic
//        _ = try! kms.createSymmetricKey(topic)
//        let messageToSerialize = "todo - change for request object"
//        let serializedMessage = try! serializer.serialize(topic: topic, encodable: messageToSerialize, envelopeType: .type0)
//        let deserializedMessage: String? = serializer.tryDeserialize(topic: topic, encodedEnvelope: serializedMessage)
//        XCTAssertEqual(messageToSerialize, deserializedMessage)
//    }
}

