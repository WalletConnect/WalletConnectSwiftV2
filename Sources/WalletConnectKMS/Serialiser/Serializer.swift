import Foundation
import Combine

public class Serializer: Serializing {

    enum Errors: Error, CustomStringConvertible {
        case symmetricKeyForTopicNotFound(String)
        case publicKeyForTopicNotFound

        var description: String {
            switch self {
            case .symmetricKeyForTopicNotFound(let topic):
                return "Error: Symmetric key for topic '\(topic)' was not found."
            case .publicKeyForTopicNotFound:
                return "Error: Public key for topic was not found."
            }
        }
    }

    private let kms: KeyManagementServiceProtocol
    private let codec: Codec
    private let logger: ConsoleLogging
    public var logsPublisher: AnyPublisher<Log, Never> {
        logger.logsPublisher.eraseToAnyPublisher()
    }

    init(kms: KeyManagementServiceProtocol, codec: Codec = ChaChaPolyCodec(), logger: ConsoleLogging) {
        self.kms = kms
        self.codec = codec
        self.logger = logger
    }

    public init(kms: KeyManagementServiceProtocol, logger: ConsoleLogging) {
        self.kms = kms
        self.codec = ChaChaPolyCodec()
        self.logger = logger
    }

    public func setLogging(level: LoggingLevel) {
        logger.setLogging(level: level)
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
            let error = Errors.symmetricKeyForTopicNotFound(topic)
            logger.error("\(error)")
            throw error
        }
        let sealbox = try codec.encode(plaintext: messageJson, symmetricKey: symmetricKey)
        return Envelope(type: envelopeType, sealbox: sealbox).serialised()
    }

    /// Deserializes and decrypts an object
    /// - Parameters:
    ///   - topic: Topic that is associated with a symetric key for decrypting particular codable object
    ///   - encodedEnvelope: Envelope to deserialize and decrypt
    /// - Returns: Deserialized object
    public func deserialize<T: Codable>(topic: String, encodedEnvelope: String) throws -> (T, derivedTopic: String?, decryptedPayload: Data) {
        let envelope = try Envelope(encodedEnvelope)
        switch envelope.type {
        case .type0:
            let deserialisedType: (object: T, data: Data) = try handleType0Envelope(topic, envelope)
            return (deserialisedType.object, nil, deserialisedType.data)
        case .type1(let peerPubKey):
            return try handleType1Envelope(topic, peerPubKey: peerPubKey, sealbox: envelope.sealbox)
        }
    }

    private func handleType0Envelope<T: Codable>(_ topic: String, _ envelope: Envelope) throws -> (T, Data) {
        if let symmetricKey = kms.getSymmetricKeyRepresentable(for: topic) {
            do {
                let decoded: (T, Data) = try decode(sealbox: envelope.sealbox, symmetricKey: symmetricKey)
                logger.debug("Decoded: \(decoded.0)")
                return decoded
            }
            catch {
                logger.error("\(error)")
                throw error
            }
        } else {
            let error = Errors.symmetricKeyForTopicNotFound(topic)
            logger.error("\(error)")
            throw error
        }
    }
    
    private func handleType1Envelope<T: Codable>(_ topic: String, peerPubKey: Data, sealbox: Data) throws -> (T, String, Data) {
        guard let selfPubKey = kms.getPublicKey(for: topic)
        else {
            let error = Errors.publicKeyForTopicNotFound
            logger.error("\(error)")
            throw error
        }

        let agreementKeys = try kms.performKeyAgreement(selfPublicKey: selfPubKey, peerPublicKey: peerPubKey.toHexString())
        let decodedType: (object: T, data: Data) = try decode(sealbox: sealbox, symmetricKey: agreementKeys.sharedKey.rawRepresentation)
        let derivedTopic = agreementKeys.derivedTopic()
        try kms.setAgreementSecret(agreementKeys, topic: derivedTopic)
        return (decodedType.object, derivedTopic, decodedType.data)
    }

    private func decode<T: Codable>(sealbox: Data, symmetricKey: Data) throws -> (T, Data) {
        var decryptedData = Data()
        print(T.self)
        do {
            decryptedData = try codec.decode(sealbox: sealbox, symmetricKey: symmetricKey)
            let decodedType = try JSONDecoder().decode(T.self, from: decryptedData)
            return (decodedType, decryptedData)
        } catch {
            let str = String(decoding: decryptedData, as: UTF8.self)
            print(str)
            logger.error("Failed to decode with error: \(error)")
            throw error
        }
    }
}
