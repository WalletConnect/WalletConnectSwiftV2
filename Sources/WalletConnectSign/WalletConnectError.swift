enum WalletConnectError: Error {

    case pairingProposalFailed
    case noPairingMatchingTopic(String)
    case noSessionMatchingTopic(String)
    case sessionNotAcknowledged(String)
    case pairingNotSettled(String)
    case invalidMethod
    case invalidEvent
    case invalidUpdateExpiryValue
    case unauthorizedNonControllerCall
    case pairingAlreadyExist
    case topicGenerationFailed
    case invalidPermissions // TODO: Refactor into actual cases
    case unsupportedNamespace(SignReasonCode)
    case emptySessionProperties

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
        case .noPairingMatchingTopic(let topic):
            return "There is no existing pairing matching the topic: \(topic)."
        case .noSessionMatchingTopic(let topic):
            return "There is no existing session matching the topic: \(topic)."
        case .sessionNotAcknowledged(let topic):
            return "Session is not settled on topic \(topic)."
        case .pairingNotSettled(let topic):
            return "Pairing is not settled on topic \(topic)."
        case .invalidUpdateExpiryValue:
            return "Update expiry time is out of expected range"
        case .invalidMethod:
            return "Methods set is invalid."
        case .invalidEvent:
            return "Invalid event type."
        case .unauthorizedNonControllerCall:
            return "Method must be called by a controller client."
        case .topicGenerationFailed:
            return "Failed to generate topic from random bytes."
        case .pairingAlreadyExist:
            return "Pairing already exist"
        case .invalidPermissions:
            return "Invalid permissions for call."
        case .unsupportedNamespace(let reason):
            return reason.message
        case .internal: // TODO: Remove internal case
            return ""
        case .emptySessionProperties:
            return "Session properties cannot be empty when set"
        }
    }
}
