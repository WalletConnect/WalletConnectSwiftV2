
import Foundation

extension PairingType {
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
    }
}
