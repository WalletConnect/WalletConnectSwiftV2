import Foundation

/// https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-25.md
public enum RejectionReason {
    case userRejected
    case userRejectedChains
    case userRejectedMethods
    case userRejectedEvents
}

internal extension RejectionReason {
    func internalRepresentation() -> ReasonCode {
        switch self {
        case .userRejected:
            return ReasonCode.userRejected
        case .userRejectedChains:
            return ReasonCode.userRejectedChains
        case .userRejectedMethods:
            return ReasonCode.userRejectedMethods
        case  .userRejectedEvents:
            return ReasonCode.userRejectedEvents
        }
    }
}
