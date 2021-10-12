
import Foundation

extension SessionType {
    enum SequenceState: Codable, Equatable {
        case settled(Settled)
        case pending(Pending)
        enum CodingKeys: CodingKey {
            case settled
            case pending
        }
        var topic: String {
            switch self {
            case .settled(let sequence):
                return sequence.topic
            case .pending(let sequence):
                return sequence.topic
            }
        }
        static func == (lhs: SequenceState, rhs: SequenceState) -> Bool {
            switch (lhs, rhs) {
            case (.pending(let lhsPending), .pending(let rhsPending)):
                return lhsPending.isEqual(to: rhsPending)
            case (.settled(let lhsSettled), .settled(let rhsSettled)):
                return lhsSettled.isEqual(to: rhsSettled)
            default:
                return false
            }
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            if let value = try? values.decode(SessionType.Settled.self, forKey: .settled) {
                self = .settled(value)
            } else if let value = try? values.decode(SessionType.Pending.self, forKey: .pending) {
                self = .pending(value)
            }
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Error"))
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .settled(let value):
                try container.encode(value, forKey: .settled)
            case .pending(let value):
                try container.encode(value, forKey: .pending)
            }
        }
    }
    
}
