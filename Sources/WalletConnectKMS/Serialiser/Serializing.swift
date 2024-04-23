import Foundation
import Combine

public protocol Serializing {
    var logsPublisher: AnyPublisher<Log, Never> {get}
    var logger: ConsoleLogging {get}
    func setLogging(level: LoggingLevel)
    func serialize(topic: String?, encodable: Encodable, envelopeType: Envelope.EnvelopeType) throws -> String
    /// - derivedTopic: topic derived from symmetric key as a result of key exchange if peers has sent envelope(type1) prefixed with it's public key
    func deserialize<T: Codable>(topic: String, codingType: Envelope.CodingType) throws -> (T, derivedTopic: String?, decryptedPayload: Data)
}

public extension Serializing {
    /// - derivedTopic: topic derived from symmetric key as a result of key exchange if peers has sent envelope(type1) prefixed with it's public key
    func tryDeserialize<T: Codable>(topic: String, codingType: Envelope.CodingType) -> (T, derivedTopic: String?, decryptedPayload: Data)? {
        return try? deserialize(topic: topic, codingType: codingType)
    }

    func serialize(topic: String?, encodable: Encodable, envelopeType: Envelope.EnvelopeType = .type0) throws -> String {
        try serialize(topic: topic, encodable: encodable, envelopeType: envelopeType)
    }

    func tryDeserializeRequestOrResponse(topic: String, codingType: Envelope.CodingType) -> Either<(request: RPCRequest, derivedTopic: String?, decryptedPayload: Data), (response: RPCResponse, derivedTopic: String?, decryptedPayload: Data)>? {
        // Attempt to deserialize RPCRequest
        if let result = try? deserialize(topic: topic, codingType: codingType) as (RPCRequest, derivedTopic: String?, decryptedPayload: Data) {
            return .left(result)
        }

        // Attempt to deserialize RPCResponse
        if let result = try? deserialize(topic: topic, codingType: codingType) as (RPCResponse, derivedTopic: String?, decryptedPayload: Data) {
            return .right(result)
        }

        // If both attempts fail, log an error and return nil
        logger.error("Failed to deserialize both request and response for topic: \(topic)")
        return nil
    }

}
