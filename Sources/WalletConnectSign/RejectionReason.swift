import Foundation

/// https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-25.md
public enum RejectionReason {
    case disapprovedChains
    case disapprovedMethods
    case disapprovedEventTypes
}

internal extension RejectionReason {
    func internalRepresentation() -> ReasonCode {
        switch self {
        case .disapprovedChains:
            return ReasonCode.userRejectedChains
        case .disapprovedMethods:
            return ReasonCode.userRejectedMethods
        case  .disapprovedEventTypes:
            return ReasonCode.userRejectedEvents
        }
    }
}
