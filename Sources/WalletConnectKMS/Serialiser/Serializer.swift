import Foundation
import WalletConnectUtils

/// A type representing serialization policy
/// tp = type byte (1 byte)
/// pk = public key (32 bytes)
/// iv = initialization vector (12 bytes)
/// ct = ciphertext (N bytes)
public enum SerializationPolicy {
    enum Errors: Error {
        case unsupportedPolicyType
    }
    /// type 0 = tp + iv + ct + tag
    case type0
    /// type 1 = tp + pk + iv + ct + tag
    case type1

    var representingByte: Int8 {
        switch self {
        case .type0:
            return 0
        case .type1:
            return 1
        }
    }

    init(byte: Int8) throws {
        if byte == 0 {
            self = .type0
        } else if byte == 1 {
            self = .type1
        } else {
            throw Errors.unsupportedPolicyType
        }
    }
}

public class Serializer {
    enum Errors: String, Error {
        case symmetricKeyForTopicNotFound
        case malformedEnvelope
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
            throw Errors.symmetricKeyForTopicNotFound
        }
    }
    
    /// Deserializes and decrypts an object
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for decrypting particular codable object
    ///   - message: Message to deserialize and decrypt
    /// - Returns: Deserialized object
    public func tryDeserialize<T: Codable>(topic: String, message: String) -> T? {
        do {
            let _: T
            if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
                return try deserialize(message: message, symmetricKey: symmetricKey)
            } else {
                throw Errors.symmetricKeyForTopicNotFound
            }
        } catch {
            return nil
        }
    }
    
    private func deserialize<T: Codable>(message: String, symmetricKey: Data) throws -> T {
        guard let envelopeData = Data(base64Encoded: message) else {
            throw Errors.malformedEnvelope
        }
        let policy = SerializationPolicy(byte: <#T##Int8#>)


        let decryptedData = try codec.decode(sealboxData: <#T##Data#>, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
}

