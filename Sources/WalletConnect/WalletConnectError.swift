// 

import Foundation

// TODO: Migrate protocol errors to ReasonCode enum over time. Use WalletConnectError for client errors only.
enum WalletConnectError: Error {
    
    case noSessionMatchingTopic(String)
    case sessionNotSettled(String)
    case invalidCAIP10Account(String)
    case invalidPermissions
    case invalidNotificationType
    case unauthorizedNonControllerCall
    
    case `internal`(_ reason: InternalReason)
    
    enum InternalReason: Error {
        case notApproved
        case malformedPairingURI
        case unauthorizedMatchingController
        case noSequenceForTopic
        case pairingProposalGenerationFailed
        case subscriptionIdNotFound
        case keyNotFound
        case deserialisationFailed
        case jsonRpcDuplicateDetected
        case noJsonRpcRequestMatchingResponse
        case pairWithExistingPairingForbidden
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
        default:
            return 0
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .noSessionMatchingTopic(let topic):
            return "No session found matching topic \(topic)."
        case .sessionNotSettled(let topic):
            return "Session is not settled on topic \(topic)."
        case .invalidCAIP10Account(let account):
            return "The account ID \(account) does not conform to CAIP-10."
        case .invalidPermissions:
            return "Permission set is invalid."
        case .invalidNotificationType:
            return "Invalid notification type."
        case .unauthorizedNonControllerCall:
            return "Method must be called by a controller client."
        case .internal(let reason):
            return reason.description
        }
    }
}

extension WalletConnectError.InternalReason: CustomStringConvertible {
    
    //FIX add codes matching js repo
    var code: Int {
        switch self {
        case .notApproved: return 1601
        case .malformedPairingURI: return 1001
        case .unauthorizedMatchingController: return 1002
        case .noSequenceForTopic: return 1003
        case .pairingProposalGenerationFailed: return 1004
        case .subscriptionIdNotFound: return 1005
        case .keyNotFound: return 1006
        case .deserialisationFailed: return 1007
        case .jsonRpcDuplicateDetected: return 1008
        case .pairWithExistingPairingForbidden: return 1009
        case .noJsonRpcRequestMatchingResponse: return 1010
        }
    }
    
    //FIX descriptions
    var description: String {
        switch self {
        case .notApproved:
            return "Session not approved"
        case .malformedPairingURI:
            return "Pairing URI string is invalid."
        case .unauthorizedMatchingController:
            return "unauthorizedMatchingController"
        case .noSequenceForTopic:
            return "noSequenceForTopic"
        case .pairingProposalGenerationFailed:
            return "pairingProposalGenerationFailed"
        case .subscriptionIdNotFound:
            return "Subscription Id Not Found"
        case .keyNotFound:
            return "Key Not Found"
        case .deserialisationFailed:
            return "Deserialisation Failed"
        case .jsonRpcDuplicateDetected:
            return "Json Rpc Duplicate Detected"
        case .noJsonRpcRequestMatchingResponse:
            return "No matching JSON RPC request for given response"
        case .pairWithExistingPairingForbidden:
            return "Pairing for uri already exist - Action Forbidden"
        }
    }
}
