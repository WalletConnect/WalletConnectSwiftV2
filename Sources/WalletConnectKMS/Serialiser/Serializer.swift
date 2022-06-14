import Foundation
import WalletConnectUtils

/// A type representing serialization policy
/// tp = type byte (1 byte)
/// pk = public key (32 bytes)
/// iv = initialization vector (12 bytes)
/// ct = ciphertext (N bytes)
public enum SerializationPolicy {
    /// type 0 = tp + iv + ct + tag
    case type0
    /// type 1 = tp + pk + iv + ct + tag
    case type1
}

public class Serializer {
    enum Error: String, Swift.Error {
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
    public func serialize(topic: String, encodable: Encodable, policy: SerializationPolicy = SerializationPolicy.type0) throws -> String {
        let messageJson = try encodable.json()
        if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
            return try codec.encode(plaintext: messageJson, symmetricKey: symmetricKey)
        } else {
            throw Error.symmetricKeyForTopicNotFound
        }
    }
    
    /// Deserializes and decrypts an object
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for decrypting particular codable object
    ///   - message: Message to deserialize and decrypt
    /// - Returns: Deserialized object
    public func tryDeserialize<T: Codable>(topic: String, message: String) -> T? {
        do {
            let deserializedCodable: T
            if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
                return try deserialize(message: message, symmetricKey: symmetricKey)
            } else {
                throw Error.symmetricKeyForTopicNotFound
            }
        } catch {
            return nil
        }
    }
    
    private func deserialize<T: Codable>(message: String, symmetricKey: Data) throws -> T {
        let decryptedData = try codec.decode(sealboxString: message, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
}

