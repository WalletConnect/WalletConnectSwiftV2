
import Foundation

enum SequenceState: Codable, Equatable {
    case settled(SequenceSettled)
    case pending(SequencePending)
    
    enum CodingKeys: CodingKey {
        case settled
        case pending
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
    
    var topic: String {
        switch self {
        case .settled(let sequence):
            return sequence.topic
        case .pending(let sequence):
            return sequence.topic
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(PairingType.Settled.self, forKey: .settled) {
            self = .settled(value)
        } else if let value = try? values.decode(PairingType.Pending.self, forKey: .pending) {
            self = .pending(value)
        } else if let value = try? values.decode(SessionType.Settled.self, forKey: .settled) {
            self = .settled(value)
        } else if let value = try? values.decode(SessionType.Pending.self, forKey: .pending) {
            self = .pending(value)
        } else {
            throw SequenceStateCodingError.decoding
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .settled(let value):
            if let pairingSettled = value as? PairingType.Settled {
                try container.encode(pairingSettled, forKey: .settled)
            } else if let sessionSettled = value as? SessionType.Settled {
                try container.encode(sessionSettled, forKey: .settled)
            }
        case .pending(let value):
            if let pairingPending = value as? PairingType.Pending {
                try container.encode(pairingPending, forKey: .pending)
            } else if let pairingPending = value as? SessionType.Pending {
                try container.encode(pairingPending, forKey: .pending)
            }
        }
    }
    
    enum SequenceStateCodingError: Error {
        case decoding
    }
}
 
