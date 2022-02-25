enum WalletConnectError: Error {
    
    case pairingProposalFailed
    case malformedPairingURI
    case noPairingMatchingTopic(String)
    case noSessionMatchingTopic(String)
    case sessionNotSettled(String)
    case pairingNotSettled(String)
    case invalidPermissions
    case invalidNotificationType
    case invalidExtendTime
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
        case .pairingProposalFailed:
            return "Pairing proposal failed."
        case .malformedPairingURI:
            return "Pairing URI string is invalid."
        case .noPairingMatchingTopic(let topic):
            return "There is no existing pairing matching the topic: \(topic)."
        case .noSessionMatchingTopic(let topic):
            return "There is no existing session matching the topic: \(topic)."
        case .sessionNotSettled(let topic):
            return "Session is not settled on topic \(topic)."
        case .pairingNotSettled(let topic):
            return "Pairing is not settled on topic \(topic)."
        case .invalidExtendTime:
            return "Extend time is out of expected range"
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
