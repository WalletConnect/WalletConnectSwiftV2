import Foundation

public protocol Serializing {
    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType) throws -> String
    func deserialize<T: Codable>(topic: String, encodedEnvelope: String) throws -> T
}

public extension Serializing {
    func tryDeserialize<T: Codable>(topic: String, encodedEnvelope: String) -> T? {
        return try? deserialize(topic: topic, encodedEnvelope: encodedEnvelope)
    }

    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType = .type0) throws -> String {
        try serialize(topic: topic, encodable: encodable, envelopeType: envelopeType)
    }
}
