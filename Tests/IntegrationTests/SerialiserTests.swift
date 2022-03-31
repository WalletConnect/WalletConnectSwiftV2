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
    
    func testSerialise() {
        let topic = "topic"
        let key = Data(hex: "0653ca620c7b4990392e1c53c4a51c14a2840cd20f0f1524cf435b17b6fe988c")
        let symKey = try! SymmetricKey(rawRepresentation: key)
        try! kms.setSymmetricKey(symKey, for: topic)
        let messageToSerialize = "WalletConnect"
        let serializedMessage = try! serializer.serialize(topic: topic, encodable: messageToSerialize)
        XCTAssertEqual(serializedMessage, "5JJK04yH8m/DmHWxvEQ7u09nkK1IxOJqlTJ1CqQ=")
    }
}

