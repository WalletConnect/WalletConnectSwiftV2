
import Foundation

enum SequenceData: Equatable {
    case settled(PairingType.Settled)
    case pending(PairingType.Pending)
    static func == (lhs: SequenceData, rhs: SequenceData) -> Bool {
        switch (lhs, rhs) {
        case (.pending(let lhsPending), .pending(let rhsPending)):
            return lhsPending == rhsPending
        case (.settled(let lhsSettled), .settled(let rhsSettled)):
            return lhsSettled == rhsSettled
        default:
            return false
        }
    }
}

struct SubscriptionParams: Equatable {
    let id: String
    let topic: String
    let sequence: SequenceData
}
