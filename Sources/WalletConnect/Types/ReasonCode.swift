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
    case invalidUpdateExpiryRequest
    case noContextWithTopic(context: Context, topic: String)
    
    // 3000 (Unauthorized)
    case unauthorizedTargetChain(String)
    case unauthorizedRPCMethod(String)
    case unauthorizedEventType(String)
    case unauthorizedUpdateRequest(context: Context)
    case unauthorizedUpdateExpiryRequest
    case unauthorizedMatchingController(isController: Bool)
    
    // 5000
    case disapprovedChains
    case disapprovedMethods
    case disapprovedNotificationTypes
    
    var code: Int {
        switch self {
        case .generic: return 0
        case .missingOrInvalid: return 1000
        case .invalidUpdateAccountsRequest: return 1003
            
        case .invalidUpdateMethodsRequest: return 1004
        case .invalidUpdateExpiryRequest: return 1005
        case .noContextWithTopic: return 1301
        case .unauthorizedTargetChain: return 3000
        case .unauthorizedRPCMethod: return 3001
        case .unauthorizedEventType: return 3002
            
            
        case .unauthorizedUpdateRequest: return 3003
        case .unauthorizedUpdateExpiryRequest: return 3005
        case .unauthorizedMatchingController: return 3100
        case .disapprovedChains: return 5000
        case .disapprovedMethods: return 5001
        case .disapprovedNotificationTypes: return 5002
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
        case .invalidUpdateExpiryRequest:
            return "Invalid update expiry request"
        case .noContextWithTopic(let context, let topic):
            return "No matching \(context) with topic: \(topic)"
        case .unauthorizedTargetChain(let chainId):
            return "Unauthorized target chain id requested: \(chainId)"
        case .unauthorizedRPCMethod(let method):
            return "Unauthorized JSON-RPC method requested: \(method)"
        case .unauthorizedEventType(let type):
            return "Unauthorized notification type requested: \(type)"
        case .unauthorizedUpdateRequest(let context):
            return "Unauthorized \(context) update request"
        case .unauthorizedMatchingController(let isController):
            return "Unauthorized: peer is also \(isController ? "" : "non-")controller"
        case .unauthorizedUpdateExpiryRequest:
            return "Unauthorized update expiry request"
        case .disapprovedChains:
            return "User disapproved requested chains"
        case .disapprovedMethods:
            return "User disapproved requested json-rpc methods"
        case .disapprovedNotificationTypes:
            return "User disapproved requested notification types"
        }
    }
}
