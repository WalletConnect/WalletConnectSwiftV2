import Foundation
import WalletConnectUtils



public class Serializer {
    enum Error: String, Swift.Error {
        case messageToShort = "Error: message is too short"
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
    
    /// Encrypts and serializes an object into (iv + publicKey + mac + cipherText) formatted sting
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for encrypting particular codable object
    ///   - message: Message to encrypt and serialize
    /// - Returns: Serialized String
    public func serialize(topic: String, encodable: Encodable) throws -> String {
        let messageJson = try encodable.json()
        var message: String
        if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
            message = try codec.encode(plaintext: messageJson, symmetricKey: symmetricKey)
        } else {
            message = messageJson.toHexEncodedString(uppercase: false)
        }
        return message
    }
    
    /// Deserializes and decrypts an object from (iv + publicKey + mac + cipherText) formatted sting
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for decrypting particular codable object
    ///   - message: Message to deserialize and decrypt
    /// - Returns: Deserialized object
    public func tryDeserialize<T: Codable>(topic: String, message: String) -> T? {
        do {
            let deserializedCodable: T
            if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
                deserializedCodable = try deserialize(message: message, symmetricKey: symmetricKey)
            } else {
                let jsonData = Data(hex: message)
                deserializedCodable = try JSONDecoder().decode(T.self, from: jsonData)
            }
            return deserializedCodable
        } catch {
            return nil
        }
    }
    
    private func deserialize<T: Codable>(message: String, symmetricKey: Data) throws -> T {
        let decryptedData = try codec.decode(sealboxString: message, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
}

