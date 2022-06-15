import Foundation
import WalletConnectUtils

/// A type representing envelope serialization policy
/// tp = type byte (1 byte)
/// pk = public key (32 bytes)
/// iv = initialization vector (12 bytes)
/// ct = ciphertext (N bytes)
public enum EnvelopeType: Equatable {
    enum Errors: Error {
        case unsupportedPolicyType
    }
    /// type 0 = tp + iv + ct + tag
    case type0
    /// type 1 = tp + pk + iv + ct + tag
    case type1(pubKey: AgreementPublicKey)

    var representingByte: UInt8 {
        switch self {
        case .type0:
            return 0
        case .type1:
            return 1
        }
    }
}

public struct Envelope {
    enum Errors: String, Error {
        case malformedEnvelope
        case unsupportedEnvelopeType
    }

    public let type: EnvelopeType
    public let sealbox: Data

    public init(_ base64encoded: String) throws {
        guard let envelopeData = Data(base64Encoded: base64encoded) else {
            throw Errors.malformedEnvelope
        }
        let envelopeTypeByte = envelopeData.subdata(in: 0..<1).uint8
        if envelopeTypeByte == 0 {
            self.type = .type0
            self.sealbox =
        } else if envelopeTypeByte == 1 {
            let pubKey = try AgreementPublicKey(hex: envelopeData.subdata(in: 0..<33).toHexString())
            self.type = .type1(pubKey: pubKey)
            self.sealbox =
        } else {
            throw Errors.unsupportedEnvelopeType
        }
    }

}

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
    public func serialize(topic: String, encodable: Encodable, envelopeType: EnvelopeType = EnvelopeType.type0) throws -> String {
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
    public func tryDeserialize<T: Codable>(topic: String, message: String) -> T? {
        do {
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

        let envelopeTypeData = envelopeData.subdata(in: 0..<1)

        let envelopeType = try EnvelopeType(byte: envelopeTypeData.uint8)
        var sealBoxData: Data!
        switch envelopeType {
        case .type0:
            sealBoxData =
        case .type1:
            sealBoxData =
            let pubKey =
        }


        let decryptedData = try codec.decode(sealboxData: sealBoxData, symmetricKey: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
}

