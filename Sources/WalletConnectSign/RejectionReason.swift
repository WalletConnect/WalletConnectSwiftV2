import Foundation

/// https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-25.md
public enum RejectionReason {
    case userRejected
    case unsupportedChains
    case unsupportedMethods
    case unsupportedAccounts
    case upsupportedEvents
}

internal extension RejectionReason {
    func internalRepresentation() -> SignReasonCode {
        switch self {
        case .userRejected:
            return SignReasonCode.userRejected
        case .unsupportedChains:
            return SignReasonCode.unsupportedChains
        case .unsupportedMethods:
            return SignReasonCode.userRejectedMethods
        case  .upsupportedEvents:
            return SignReasonCode.userRejectedEvents
        case .unsupportedAccounts:
            return SignReasonCode.unsupportedAccounts
        }
    }
}

public extension RejectionReason {
    init(from error: AutoNamespacesError) {
        switch error {
        case .requiredChainsNotSatisfied:
            self = .unsupportedChains
        case .requiredAccountsNotSatisfied:
            self = .unsupportedAccounts
        case .requiredMethodsNotSatisfied:
            self = .unsupportedMethods
        case .requiredEventsNotSatisfied:
            self = .upsupportedEvents
        case .emptySessionNamespacesForbidden:
            self = .unsupportedAccounts
        }
    }
}
