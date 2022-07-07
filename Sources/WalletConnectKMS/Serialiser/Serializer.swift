import Foundation
import WalletConnectUtils

public class Serializer: Serializing {
    enum Errors: String, Error {
        case symmetricKeyForTopicNotFound
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
    public func tryDeserialize<T: Codable>(topic: String, encodedEnvelope: String) -> T? {
        do {
            let envelope = try Envelope(encodedEnvelope)
            switch envelope.type {
            case .type0:
                let decodedType: T? = try handleType0Envelope(topic, envelope)
                return decodedType
            case .type1:
                let decodedType: T? = try handleType1Envelope(topic, envelope)
                return decodedType
            }
        } catch {
            print(error)
            return nil
        }
    }

    private func handleType0Envelope<T: Codable>(_ topic: String, _ envelope: Envelope) throws -> T? {
        if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
            return try decode(sealbox: envelope.sealbox, symmetricKey: symmetricKey)
        } else {
            throw Errors.symmetricKeyForTopicNotFound
        }
    }

    private func handleType1Envelope<T: Codable>(_ topic: String, _ envelope: Envelope) throws -> T? {
        guard let selfPubKey = kms.getPublicKey(for: topic),
              case let .type1(peerPubKey) = envelope.type else { return nil }
        do {
            //self pub key is good
            let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.toHexString())
            let decodedType: T? = try decode(sealbox: envelope.sealbox, symmetricKey: agreementKeys.sharedKey.rawRepresentation)
            let newTopic = agreementKeys.derivedTopic()
            try kms.setAgreementSecret(agreementKeys, topic: newTopic)
            return decodedType
        } catch {
            print(error)
        }
        return nil
    }

    private func decode<T: Codable>(sealbox: Data, symmetricKey: Data) throws -> T {
        let decryptedData = try codec.decode(sealbox: sealbox, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
}
