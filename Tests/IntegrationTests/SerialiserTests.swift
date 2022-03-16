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
    
//    TODO - change pairing serialisation for sessions
    func testSerializeDeserialize() {
        let topic = TopicGenerator().topic
        _ = try! kms.createSymmetricKey(topic)
        let messageToSerialize = "todo - change for request object"
        let serializedMessage = try! serializer.serialize(topic: topic, encodable: messageToSerialize)
        let deserializedMessage: String? = serializer.tryDeserialize(topic: topic, message: serializedMessage)
        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }
}

