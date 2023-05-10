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
        let (deserializedMessage, _, _): (String, String?, Data) = mySerializer.tryDeserialize(topic: topic, encodedEnvelope: serializedMessage)!
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
        let (deserializedMessage, _, _): (String, String?, Data) = mySerializer.tryDeserialize(topic: topic, encodedEnvelope: serializedMessage)!
        XCTAssertEqual(messageToSerialize, deserializedMessage)
    }
}
