
import Foundation

enum SequenceState: Equatable {
    case settled(SequenceSettled)
    case pending(SequencePending)
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
}
 
