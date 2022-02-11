// 

import Foundation

// TODO: Migrate protocol errors to ReasonCode enum over time. Use WalletConnectError for client errors only.
enum WalletConnectError: Error {
    
    case noPairingMatchingTopic(String)
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
        case pairingProposalGenerationFailed
        case subscriptionIdNotFound
        case keyNotFound
        case deserialisationFailed
        case jsonRpcDuplicateDetected
        case noJsonRpcRequestMatchingResponse
        case pairWithExistingPairingForbidden
    }
}

extension WalletConnectError {
    
    var localizedDescription: String {
        switch self {
        case .noPairingMatchingTopic(let topic):
            return "There is no existing pairing matching the topic: \(topic)."
        case .noSessionMatchingTopic(let topic):
            return "There is no existing session matching the topic: \(topic)."
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
        case .internal(_):
            return ""
        }
    }
}
