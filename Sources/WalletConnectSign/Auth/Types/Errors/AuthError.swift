import Foundation

/// Authentication error
public enum AuthError: Codable, Equatable, Error, LocalizedError {
    case methodUnsupported
    case userDisconnected
    case userRejeted
    case malformedResponseParams
    case malformedRequestParams
    case messageCompromised
    case signatureVerificationFailed
    case userRejectedRequest
}

extension AuthError: Reason {

    init?(code: Int) {
        switch code {
        case Self.methodUnsupported.code:
            self = .methodUnsupported
        case Self.userRejeted.code:
            self = .userRejeted
        case Self.malformedResponseParams.code:
            self = .malformedResponseParams
        case Self.malformedRequestParams.code:
            self = .malformedRequestParams
        case Self.messageCompromised.code:
            self = .messageCompromised
        case Self.signatureVerificationFailed.code:
            self = .signatureVerificationFailed
        case Self.userRejectedRequest.code:
            self = .userRejectedRequest
        default:
            return nil
        }
    }

    public var code: Int {
        switch self {
        case .methodUnsupported:
            return 10001
        case .userDisconnected:
            return 6000
        case .userRejeted:
            return 14001
        case .malformedResponseParams:
            return 11001
        case .malformedRequestParams:
            return 11002
        case .messageCompromised:
            return 11003
        case .signatureVerificationFailed:
            return 11004
        case .userRejectedRequest:
            return 12001
        }
    }

    public var message: String {
        switch self {
        case .methodUnsupported:
            return "Method Unsupported"
        case .userRejeted:
            return "Auth request rejected by the user"
        case .malformedResponseParams:
            return "Response params malformed"
        case .malformedRequestParams:
            return "Request params malformed"
        case .messageCompromised:
            return "Original message compromised"
        case .signatureVerificationFailed:
            return "Message verification failed"
        case .userDisconnected:
            return "User Disconnected"
        case .userRejectedRequest:
            return "User Rejected Request"
        }
    }

    public var errorDescription: String? {
        return message
    }
}
