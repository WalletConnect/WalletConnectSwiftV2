enum SignReasonCode: Reason, Codable, Equatable {

    enum Context: String, Codable {
        case pairing = "pairing"
        case session = "session"
    }

    // 1000 - (Internal)
    case invalidMethod
    case invalidEvent
    case invalidUpdateRequest
    case invalidExtendRequest
    case noSessionForTopic

    // 3000 - (Unauthorized)
    case unauthorizedMethod(String)
    case unauthorizedEvent(String)
    case unauthorizedUpdateRequest
    case unauthorizedExtendRequest
    case unauthorizedChain

    // 4001 - (EIP-1193)
    case userRejectedRequest

    // 5000 - (REJECTED (CAIP-25))
    case userRejected
    case userRejectedChains
    case userRejectedMethods
    case userRejectedEvents

    case unsupportedChains
    case unsupportedMethods
    case unsupportedEvents
    case unsupportedAccounts
    case unsupportedNamespaceKey

    // 6000
    case userDisconnected

    // 7000
    case sessionSettlementFailed
    // 8000
    case sessionRequestExpired

    var code: Int {
        switch self {
        case .invalidMethod: return 1001
        case .invalidEvent: return 1002
        case .invalidUpdateRequest: return 1003
        case .invalidExtendRequest: return 1004

        case .unauthorizedMethod: return 3001
        case .unauthorizedEvent: return 3002
        case .unauthorizedUpdateRequest: return 3003
        case .unauthorizedExtendRequest: return 3004
        case .unauthorizedChain: return 3005

        case .userRejectedRequest: return 4001

        case .userRejected: return 5000
        case .userRejectedChains: return 5001
        case .userRejectedMethods: return 5002
        case .userRejectedEvents: return 5003

        case .unsupportedChains: return 5100
        case .unsupportedMethods: return 5101
        case .unsupportedEvents: return 5102
        case .unsupportedAccounts: return 5103
        case .unsupportedNamespaceKey: return 5104

        case .userDisconnected: return 6000

        case .sessionSettlementFailed: return 7000
        case .noSessionForTopic: return 7001
        case .sessionRequestExpired: return 8000
        }
    }

    var message: String {
        switch self {
        case .invalidMethod:
            return "Invalid Method"
        case .invalidEvent:
            return "Invalid Event"
        case .invalidUpdateRequest:
            return "Invalid update namespace request"
        case .invalidExtendRequest:
            return "Invalid update expiry request"
        case .unauthorizedMethod(let method):
            return "Unauthorized JSON-RPC method requested: \(method)"
        case .unauthorizedEvent(let type):
            return "Unauthorized event type requested: \(type)"
        case .unauthorizedUpdateRequest:
            return "Unauthorized update request"
        case .unauthorizedExtendRequest:
            return "Unauthorized extend request"
        case .unauthorizedChain:
            return "Unauthorized target chain id requested"

        case .userRejectedRequest:
            return "User rejected request"

        case .userRejected:
            return "User rejected"
        case .userRejectedChains:
            return "User disapproved requested chains"
        case .userRejectedMethods:
            return "User disapproved requested json-rpc methods"
        case .userRejectedEvents:
            return "User disapproved requested event types"

        case .unsupportedChains:
            return "Unsupported or empty chains for namespace"
        case .unsupportedMethods:
            return "Unsupported methods for namespace"
        case .unsupportedEvents:
            return "Unsupported events for namespace"
        case .unsupportedAccounts:
            return "Unsupported or empty accounts for namespace"
        case .unsupportedNamespaceKey:
            return "Unsupported namespace key"
        case .userDisconnected:
            return "User discconnected"
        case .sessionSettlementFailed:
            return "Session Settlement Failed"
        case .noSessionForTopic:
            return "No matching session matching topic"
        case .sessionRequestExpired:
            return "Session request expired or expiry param validation failed (MIN_INTERVAL: 300, MAX_INTERVAL: 604800)"
        }
    }
}
