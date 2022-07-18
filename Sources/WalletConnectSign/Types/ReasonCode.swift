enum ReasonCode {

    enum Context: String {
        case pairing = "pairing"
        case session = "session"
    }

    // 0 (Generic)
    case generic(message: String)

    // 1000 (Internal)
    case missingOrInvalid(String)
    case invalidUpdateAccountsRequest
    case invalidUpdateNamespaceRequest
    case invalidUpdateExpiryRequest
    case noContextWithTopic(context: Context, topic: String)

    // 3000 (Unauthorized)
    case unauthorizedTargetChain(String)
    case unauthorizedMethod(String)
    case unauthorizedEvent(String)
    case unauthorizedUpdateAccountRequest
    case unauthorizedUpdateNamespacesRequest
    case unauthorizedUpdateExpiryRequest
    case unauthorizedMatchingController(isController: Bool)

    // 5000
    case disapprovedChains
    case disapprovedMethods
    case disapprovedEventTypes
    case unsupportedChains
    case unsupportedMethods
    case unsupportedEvents
    case unsupportedAccounts
    case unsupportedNamespaceKey

    // 6000
    case userDisconnected

    var code: Int {
        switch self {
        case .generic: return 0
        case .missingOrInvalid: return 1000

        case .invalidUpdateAccountsRequest: return 1003
        case .invalidUpdateNamespaceRequest: return 1004
        case .invalidUpdateExpiryRequest: return 1005
        case .noContextWithTopic: return 1301

        case .unauthorizedTargetChain: return 3000
        case .unauthorizedMethod: return 3001
        case .unauthorizedEvent: return 3002

        case .unauthorizedUpdateAccountRequest: return 3003
        case .unauthorizedUpdateNamespacesRequest: return 3004
        case .unauthorizedUpdateExpiryRequest: return 3005
        case .unauthorizedMatchingController: return 3100
        case .disapprovedChains: return 5000
        case .disapprovedMethods: return 5001
        case .disapprovedEventTypes: return 5002

        case .unsupportedChains: return 5100
        case .unsupportedMethods: return 5101
        case .unsupportedEvents: return 5102
        case .unsupportedAccounts: return 5103
        case .unsupportedNamespaceKey: return 5104

        case .userDisconnected: return 6000
        }
    }

    var message: String {
        switch self {
        case .generic(let message):
            return message
        case .missingOrInvalid(let name):
            return "Missing or invalid \(name)"
        case .invalidUpdateAccountsRequest:
            return "Invalid update accounts request"
        case .invalidUpdateNamespaceRequest:
            return "Invalid update namespace request"
        case .invalidUpdateExpiryRequest:
            return "Invalid update expiry request"
        case .noContextWithTopic(let context, let topic):
            return "No matching \(context) with topic: \(topic)"
        case .unauthorizedTargetChain(let chainId):
            return "Unauthorized target chain id requested: \(chainId)"
        case .unauthorizedMethod(let method):
            return "Unauthorized JSON-RPC method requested: \(method)"
        case .unauthorizedEvent(let type):
            return "Unauthorized event type requested: \(type)"
        case .unauthorizedUpdateAccountRequest:
            return "Unauthorized update accounts request"
        case .unauthorizedUpdateNamespacesRequest:
            return "Unauthorized update namespaces request"
        case .unauthorizedUpdateExpiryRequest:
            return "Unauthorized update expiry request"
        case .unauthorizedMatchingController(let isController):
            return "Unauthorized: peer is also \(isController ? "" : "non-")controller"
        case .disapprovedChains:
            return "User disapproved requested chains"
        case .disapprovedMethods:
            return "User disapproved requested json-rpc methods"
        case .disapprovedEventTypes:
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
        }
    }
}
