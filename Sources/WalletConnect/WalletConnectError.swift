enum WalletConnectError: Error {
    
    case pairingProposalFailed(Error)
    case malformedPairingURI
    case noPairingMatchingTopic(String)
    case noSessionMatchingTopic(String)
    case sessionNotSettled(String)
    case invalidCAIP10Account(String)
    case invalidPermissions
    case invalidNotificationType
    case unauthorizedNonControllerCall
    case topicGenerationFailed
    
    case `internal`(_ reason: InternalReason)
    
    enum InternalReason: Error {
        case jsonRpcDuplicateDetected
        case noJsonRpcRequestMatchingResponse
    }
}

extension WalletConnectError {
    
    var localizedDescription: String {
        switch self {
        case .pairingProposalFailed(let error):
            return "Pairing proposal failed with error: \(error.localizedDescription)"
        case .malformedPairingURI:
            return "Pairing URI string is invalid."
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
        case .topicGenerationFailed:
            return "Failed to generate topic from random bytes."
        case .internal(_): // TODO: Remove internal case
            return ""
        }
    }
}
