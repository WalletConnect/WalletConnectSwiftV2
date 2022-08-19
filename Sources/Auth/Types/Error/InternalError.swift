import Foundation

public enum InternalError: Codable, Equatable, Error {
    case malformedResponseParams
    case malformedRequestParams
    case messageCompromised
    case messageVerificationFailed
}

extension InternalError: Reason {

    public var code: Int {
        switch self {
        case .malformedResponseParams:
            return 1001
        case .malformedRequestParams:
            return 1002
        case .messageCompromised:
            return 1003
        case .messageVerificationFailed:
            return 1004
        }
    }

    public var message: String {
        switch self {
        case .malformedResponseParams:
            return "Response params malformed"
        case .malformedRequestParams:
            return "Request params malformed"
        case .messageCompromised:
            return "Original message compromised"
        case .messageVerificationFailed:
            return "Message verification failed"
        }
    }
}
