import Foundation
import WalletConnectUtils

public class Serializer: Serializing {

    enum Errors: String, Error {
        case symmetricKeyForTopicNotFound
        case publicKeyForTopicNotFound
    }

    private let kms: KeyManagementServiceProtocol
    private let codec: Codec

    init(kms: KeyManagementServiceProtocol, codec: Codec = ChaChaPolyCodec()) {
        self.kms = kms
        self.codec = codec
    }

    public init(kms: KeyManagementServiceProtocol) {
        self.kms = kms
        self.codec = ChaChaPolyCodec()
    }

    /// Encrypts and serializes an object
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for encrypting particular codable object
    ///   - encodable: Object to encrypt and serialize
    ///   - envelopeType: type of envelope
    /// - Returns: Serialized String
    public func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType) throws -> String {
        let messageJson = try encodable.json()
        guard let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) else {
            throw Errors.symmetricKeyForTopicNotFound
        }
        let sealbox = try codec.encode(plaintext: messageJson, symmetricKey: symmetricKey)
        return Envelope(type: envelopeType, sealbox: sealbox).serialised()
    }

    /// Deserializes and decrypts an object
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for decrypting particular codable object
    ///   - encodedEnvelope: Envelope to deserialize and decrypt
    /// - Returns: Deserialized object
    public func deserialize<T: Codable>(topic: String, encodedEnvelope: String) throws -> T {
        let envelope = try Envelope(encodedEnvelope)
        switch envelope.type {
        case .type0:
            return try handleType0Envelope(topic, envelope)
        case .type1(let peerPubKey):
            return try handleType1Envelope(topic, peerPubKey: peerPubKey, sealbox: envelope.sealbox)
        }
    }

    private func handleType0Envelope<T: Codable>(_ topic: String, _ envelope: Envelope) throws -> T {
        if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
            return try decode(sealbox: envelope.sealbox, symmetricKey: symmetricKey)
        } else {
            throw Errors.symmetricKeyForTopicNotFound
        }
    }

    private func handleType1Envelope<T: Codable>(_ topic: String, peerPubKey: Data, sealbox: Data) throws -> T {
        guard let selfPubKey = kms.getPublicKey(for: topic)
        else { throw Errors.publicKeyForTopicNotFound }

        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.toHexString())
        let decodedType: T = try decode(sealbox: sealbox, symmetricKey: agreementKeys.sharedKey.rawRepresentation)
        let newTopic = agreementKeys.derivedTopic()
        try kms.setAgreementSecret(agreementKeys, topic: newTopic)
        return decodedType
    }

    private func decode<T: Codable>(sealbox: Data, symmetricKey: Data) throws -> T {
        let decryptedData = try codec.decode(sealbox: sealbox, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
}
