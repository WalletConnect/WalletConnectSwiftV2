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
    case invalidUpdateMethodsRequest
    case invalidUpdateEventsRequest
    case invalidUpdateExpiryRequest
    case noContextWithTopic(context: Context, topic: String)
    
    // 3000 (Unauthorized)
    case unauthorizedTargetChain(String)
    case unauthorizedRPCMethod(String)
    case unauthorizedEventType(String)
    case unauthorizedUpdateAccountRequest
    case unauthorizedUpdateMethodsRequest
    case unauthorizedUpdateEventsRequest
    case unauthorizedUpdateExpiryRequest
    case unauthorizedMatchingController(isController: Bool)
    
    // 5000
    case disapprovedChains
    case disapprovedMethods
    case disapprovedEventTypes
    
    var code: Int {
        switch self {
        case .generic: return 0
        case .missingOrInvalid: return 1000
            
        case .invalidUpdateAccountsRequest: return 1003
        case .invalidUpdateMethodsRequest: return 1004
        case .invalidUpdateEventsRequest: return 1005
        case .invalidUpdateExpiryRequest: return 1006
        case .noContextWithTopic: return 1301
            
        case .unauthorizedTargetChain: return 3000
        case .unauthorizedRPCMethod: return 3001
        case .unauthorizedEventType: return 3002
            
        case .unauthorizedUpdateAccountRequest: return 3003
        case .unauthorizedUpdateMethodsRequest: return 3004
        case .unauthorizedUpdateEventsRequest: return 3005
        case .unauthorizedUpdateExpiryRequest: return 3005
        case .unauthorizedMatchingController: return 3100
        case .disapprovedChains: return 5000
        case .disapprovedMethods: return 5001
        case .disapprovedEventTypes: return 5002
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
        case .invalidUpdateMethodsRequest:
            return "Invalid update methods request"
        case .invalidUpdateEventsRequest:
            return "Invalid update events request"
        case .invalidUpdateExpiryRequest:
            return "Invalid update expiry request"
        case .noContextWithTopic(let context, let topic):
            return "No matching \(context) with topic: \(topic)"
        case .unauthorizedTargetChain(let chainId):
            return "Unauthorized target chain id requested: \(chainId)"
        case .unauthorizedRPCMethod(let method):
            return "Unauthorized JSON-RPC method requested: \(method)"
        case .unauthorizedEventType(let type):
            return "Unauthorized event type requested: \(type)"
        case .unauthorizedUpdateAccountRequest:
            return "Unauthorized update accounts request"
        case .unauthorizedUpdateMethodsRequest:
            return "Unauthorized update methods request"
        case .unauthorizedUpdateEventsRequest:
            return "Unauthorized update events request"
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
        }
    }
}
