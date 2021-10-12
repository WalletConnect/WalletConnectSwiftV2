// 

import Foundation

enum WalletConnectError: Error, CustomStringConvertible {
    // 1000 (Internal)
    case notApproved
    case PairingParamsUriInitialization
    case unauthorizedMatchingController
    case noSequenceForTopic
    case pairingProposalGenerationFailed
    case deserialisationFailed
    case keyNotFound

    // 2000 (Timeout)
    // 3000 (Unauthorized)
    case unAuthorizedTargetChain
    case unAuthorizedJsonRpcMethod
    // 4000 (EIP-1193)
    // 5000 (CAIP-25)
    // 9000 (Unknown)
    
    //FIX add codes matching js repo
    var code: Int {
        switch self {
        case .PairingParamsUriInitialization:
            return 0000000
        case .unauthorizedMatchingController:
            return 0000000
        case .pairingProposalGenerationFailed:
            return 0000000
        case .deserialisationFailed:
            return 000
        case .keyNotFound:
            return 0000
        case .noSequenceForTopic:
            return 0000000
        case .notApproved:
            return 1601
        case .unAuthorizedTargetChain:
            return 3000
        case .unAuthorizedJsonRpcMethod:
            return 3001
        }
    }
    
    //FIX descriptions
    var message: String {
        switch self {
        case .PairingParamsUriInitialization:
            return "PairingParamsUriInitialization"
        case .unauthorizedMatchingController:
            return "unauthorizedMatchingController"
        case .pairingProposalGenerationFailed:
            return "pairingProposalGenerationFailed"
        case .deserialisationFailed:
            return "deserialisationFailed"
        case .keyNotFound:
            return "keyNotFound"
        case .notApproved:
            return "Session not approved"
        case .unAuthorizedTargetChain:
            return "Unauthorized Target ChainId Requested"
        case .unAuthorizedJsonRpcMethod:
            return "Unauthorized JSON-RPC Method Requested"
        case .noSequenceForTopic:
            return "noSequenceForTopic"
        }
    }
    
    var description: String {
        return "code: \(code) - message: \(message)"
    }
}
