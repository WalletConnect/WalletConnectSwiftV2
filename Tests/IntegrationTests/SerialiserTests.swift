// 

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
        self.mySerializer = Serializer(kms: myKms)

        self.peerKms = KeyManagementServiceMock()
        self.peerSerializer = Serializer(kms: peerKms)
    }
    
    func testSerializeDeserializeType0Envelope() {
        let topic = TopicGenerator().topic
        _ = try! myKms.createSymmetricKey(topic)
        let messageToSerialize = "todo - change for request object"
        let serializedMessage = try! mySerializer.serialize(topic: topic, encodable: messageToSerialize, envelopeType: .type0)
        let deserializedMessage: String? = mySerializer.tryDeserialize(topic: topic, encodedEnvelope: serializedMessage)
        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }

    func testSerializeDeserializeType1Envelope() {
        let myPubKey = try! myKms.createX25519KeyPair()
        let topic = myPubKey.rawRepresentation.sha256().toHexString()
        try! myKms.setPublicKey(publicKey: myPubKey, for: topic)
        print("test.my pub key: \(myPubKey.hexRepresentation)")

        // Actions on Peer
        print("----------------Peer Serialising------------------")
        let messageToSerialize = "todo - change for request object"
        let peerPubKey = try! peerKms.createX25519KeyPair()

        print("test.peer pub key: \(peerPubKey.hexRepresentation)")

        let agreementKeys = try! peerKms.performKeyAgreement(selfPublicKey: peerPubKey, peerPublicKey: myPubKey.hexRepresentation)
        try! peerKms.setAgreementSecret(agreementKeys, topic: topic)
        let serializedMessage = try! peerSerializer.serialize(topic: topic, encodable: messageToSerialize, envelopeType: .type1(pubKey: peerPubKey.hexRepresentation))
        print(agreementKeys.sharedKey.hexRepresentation)
        print("-----------ME Deserialising -------------------")
        let deserializedMessage: String? = mySerializer.tryDeserialize(topic: topic, encodedEnvelope: serializedMessage)
        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }
}

