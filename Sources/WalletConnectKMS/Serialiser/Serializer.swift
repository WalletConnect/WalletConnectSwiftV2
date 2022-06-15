import Foundation
import WalletConnectUtils


public class Serializer {
    enum Errors: String, Error {
        case symmetricKeyForTopicNotFound
    }
    private let kms: KeyManagementServiceProtocol
    private let codec: Codec
    
    init(kms: KeyManagementServiceProtocol, codec: Codec = ChaChaPolyCodec()) {
        self.kms = kms
        self.codec = codec
    }
    
    public init(kms: KeyManagementService) {
        self.kms = kms
        self.codec = ChaChaPolyCodec()
    }
    
    /// Encrypts and serializes an object
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for encrypting particular codable object
    ///   - message: Message to encrypt and serialize
    /// - Returns: Serialized String
    public func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType = .type0) throws -> String {
        let messageJson = try encodable.json()
        guard let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) else {
            throw Errors.symmetricKeyForTopicNotFound
        }
        let sealbox = try codec.encode(plaintext: messageJson, symmetricKey: symmetricKey)
        let envelopeTypeByte = envelopeType.representingByte
        switch envelopeType {
        case .type0:
            return (envelopeTypeByte.data + sealbox).base64EncodedString()
        case .type1(let pubKey):
            return (envelopeTypeByte.data + pubKey.rawRepresentation + sealbox).base64EncodedString()
        }
    }

    /// Deserializes and decrypts an object
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for decrypting particular codable object
    ///   - message: Message to deserialize and decrypt
    /// - Returns: Deserialized object
    public func tryDeserialize<T: Codable>(topic: String, encodedEnvelope: String) throws -> T? {

        let envelope = try Envelope(encodedEnvelope)

        switch envelope.type {
        case .type0:
            let decodedType: T? = handleType0Envelope(topic, envelope)
            return decodedType
        case .type1(pubKey: let pubKey):
            let decodedType: T? = handleType1Envelope(topic, envelope)
            return decodedType
        }
    }

    private func handleType1Envelope<T: Codable>(_ topic: String, _ envelope: Envelope) -> T? {
        kms.set
    }

    private func handleType0Envelope<T: Codable>(_ topic: String, _ envelope: Envelope) -> T? {
        do {
            if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
                return try deserialize(sealbox: envelope.sealbox, symmetricKey: symmetricKey)
            } else {
                throw Errors.symmetricKeyForTopicNotFound
            }
        } catch {
            return nil
        }
    }
    
    private func deserialize<T: Codable>(sealbox: Data, symmetricKey: Data) throws -> T {
        let decryptedData = try codec.decode(sealbox: sealbox, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }

}
