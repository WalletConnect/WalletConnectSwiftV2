import Foundation

public protocol Serializing {
    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType) throws -> String
    func tryDeserialize<T: Codable>(topic: String, encodedEnvelope: String) -> T?
}

public extension Serializing {
    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType = .type0) throws -> String {
        try serialize(topic: topic, encodable: encodable, envelopeType: envelopeType)
    }
}
