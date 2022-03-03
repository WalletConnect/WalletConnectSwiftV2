enum ReasonCode {
    
    enum Context: String {
        case pairing = "pairing"
        case session = "session"
    }
    
    // 0 (Generic)
    case generic(message: String)
    
    // 1000 (Internal)
    case missingOrInvalid(String)
    case invalidUpdateRequest(context: Context)
    case invalidUpgradeRequest(context: Context)
    case invalidExtendRequest(context: Context)
    case noContextWithTopic(context: Context, topic: String)
    
    // 3000 (Unauthorized)
    case unauthorizedTargetChain(String)
    case unauthorizedRPCMethod(String)
    case unauthorizedNotificationType(String)
    case unauthorizedUpdateRequest(context: Context)
    case unauthorizedUpgradeRequest(context: Context)
    case unauthorizedExtendRequest(context: Context)
    case unauthorizedMatchingController(isController: Bool)
    
    // 5000
    case disapprovedChains
    case disapprovedMethods
    case disapprovedNotificationTypes
    
    var code: Int {
        switch self {
        case .generic: return 0
        case .missingOrInvalid: return 1000
        case .invalidUpdateRequest: return 1003
        case .invalidUpgradeRequest: return 1004
        case .invalidExtendRequest: return 1005
        case .noContextWithTopic: return 1301
        case .unauthorizedTargetChain: return 3000
        case .unauthorizedRPCMethod: return 3001
        case .unauthorizedNotificationType: return 3002
        case .unauthorizedUpdateRequest: return 3003
        case .unauthorizedUpgradeRequest: return 3004
        case .unauthorizedExtendRequest: return 3005
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
        case .invalidUpdateRequest(let context):
            return "Invalid \(context) update request"
        case .invalidUpgradeRequest(let context):
            return "Invalid \(context) upgrade request"
        case .invalidExtendRequest(context: let context):
            return "Invalid \(context) extend request"
        case .noContextWithTopic(let context, let topic):
            return "No matching \(context) with topic: \(topic)"
        case .unauthorizedTargetChain(let chainId):
            return "Unauthorized target chain id requested: \(chainId)"
        case .unauthorizedRPCMethod(let method):
            return "Unauthorized JSON-RPC method requested: \(method)"
        case .unauthorizedNotificationType(let type):
            return "Unauthorized notification type requested: \(type)"
        case .unauthorizedUpdateRequest(let context):
            return "Unauthorized \(context) update request"
        case .unauthorizedUpgradeRequest(let context):
            return "Unauthorized \(context) upgrade request"
        case .unauthorizedMatchingController(let isController):
            return "Unauthorized: peer is also \(isController ? "" : "non-")controller"
        case .unauthorizedExtendRequest(context: let context):
            return "Unauthorized \(context) extend request"
        case .disapprovedChains:
            return "User disapproved requested chains"
        case .disapprovedMethods:
            return "User disapproved requested json-rpc methods"
        case .disapprovedNotificationTypes:
            return "User disapproved requested notification types"
        }
    }
}
