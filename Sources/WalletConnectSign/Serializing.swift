
import Foundation
import WalletConnectKMS

protocol Serializing {
    func serialize(topic: String, encodable: Encodable, envelopeType: Envelope.EnvelopeType) throws -> String
    func tryDeserialize<T: Codable>(topic: String, encodedEnvelope: String) -> T?
}

extension Serializing {
    func serialize(topic: String, encodable: Encodable) throws -> String {
        try serialize(topic: topic, encodable: encodable, envelopeType: .type0)
    }

}

extension Serializer: Serializing {}

