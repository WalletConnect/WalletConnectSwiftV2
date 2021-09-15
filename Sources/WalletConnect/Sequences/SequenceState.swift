
import Foundation

enum SequenceState: Equatable {
    case settled(PairingType.Settled)
    case pending(PairingType.Pending)
    static func == (lhs: SequenceState, rhs: SequenceState) -> Bool {
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
