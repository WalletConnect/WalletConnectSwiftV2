import Foundation

/// https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-25.md
public enum RejectionReason {
    case userRejected
    case userRejectedChains
    case userRejectedMethods
    case userRejectedEvents
}

internal extension RejectionReason {
    func internalRepresentation() -> SignReasonCode {
        switch self {
        case .userRejected:
            return SignReasonCode.userRejected
        case .userRejectedChains:
            return SignReasonCode.userRejectedChains
        case .userRejectedMethods:
            return SignReasonCode.userRejectedMethods
        case  .userRejectedEvents:
            return SignReasonCode.userRejectedEvents
        }
    }
}
