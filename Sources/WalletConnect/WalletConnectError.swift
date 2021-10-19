// 

import Foundation

enum WalletConnectError: Error {
    
    // 1000 (Internal)
    case `internal`(_ reason: InternalReason)

    // 2000 (Timeout)
    // 3000 (Unauthorized)
    case unauthrorized(_ reason: UnauthorizedReason)
    
    // 4000 (EIP-1193)
    // 5000 (CAIP-25)
    // 9000 (Unknown)
    
    enum InternalReason {
        case notApproved
        case pairingParamsURIInitialization
        case unauthorizedMatchingController
        case noSequenceForTopic
        case pairingProposalGenerationFailed
    }
    
    enum UnauthorizedReason {
        case unauthorizedTargetChain
        case unauthorizedJsonRpcMethod
    }
}

extension WalletConnectError: CustomStringConvertible {
    
    var description: String {
        return "code: \(code) - message: \(localizedDescription)"
    }
    
    var code: Int {
        switch self {
        case .internal(let reason):
            return reason.code
        case .unauthrorized(let reason):
            return reason.code
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .internal(let reason):
            return reason.description
        case .unauthrorized(let reason):
            return reason.description
        }
    }
}

extension WalletConnectError.InternalReason: CustomStringConvertible {
    
    //FIX add codes matching js repo
    var code: Int {
        switch self {
        case .notApproved: return 1601
        case .pairingParamsURIInitialization: return 0000000
        case .unauthorizedMatchingController: return 0000000
        case .noSequenceForTopic: return 0000000
        case .pairingProposalGenerationFailed: return 0000000
        }
    }
    
    //FIX descriptions
    var description: String {
        switch self {
        case .notApproved:
            return "Session not approved"
        case .pairingParamsURIInitialization:
            return "PairingParamsUriInitialization"
        case .unauthorizedMatchingController:
            return "unauthorizedMatchingController"
        case .noSequenceForTopic:
            return "noSequenceForTopic"
        case .pairingProposalGenerationFailed:
            return "pairingProposalGenerationFailed"
        }
    }
}

extension WalletConnectError.UnauthorizedReason: CustomStringConvertible {
    
    var code: Int {
        switch self {
        case .unauthorizedTargetChain: return 3000
        case .unauthorizedJsonRpcMethod: return 3001
        }
    }
    
    var description: String {
        switch self {
        case .unauthorizedTargetChain:
            return "Unauthorized Target ChainId Requested"
        case .unauthorizedJsonRpcMethod:
            return "Unauthorized JSON-RPC Method Requested"
        }
    }
}
