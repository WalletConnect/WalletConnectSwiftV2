import Foundation

public protocol Serializing {
    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType) throws -> String
    /// - derivedTopic: topic derived from symmetric key as a result of key exchange if peers has sent envelope(type1) prefixed with it's public key
    func deserialize<T: Codable>(topic: String, encodedEnvelope: String) throws -> (T, derivedTopic: String?, decryptedPayload: Data)
}

public extension Serializing {
    /// - derivedTopic: topic derived from symmetric key as a result of key exchange if peers has sent envelope(type1) prefixed with it's public key
    func tryDeserialize<T: Codable>(topic: String, encodedEnvelope: String) -> (T, derivedTopic: String?, decryptedPayload: Data)? {
        return try? deserialize(topic: topic, encodedEnvelope: encodedEnvelope)
    }

    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType = .type0) throws -> String {
        try serialize(topic: topic, encodable: encodable, envelopeType: envelopeType)
    }
}
