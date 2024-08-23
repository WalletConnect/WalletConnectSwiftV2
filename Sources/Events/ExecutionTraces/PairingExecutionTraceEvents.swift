
import Foundation

public enum PairingExecutionTraceEvents: String, TraceEventItem {
    case pairingUriValidationSuccess = "pairing_uri_validation_success"
    case pairingStarted = "pairing_started"
    case noWssConnection = "no_wss_connection"
    case storeNewPairing = "store_new_pairing"
    case subscribingPairingTopic = "subscribing_pairing_topic"
    case subscribePairingTopicSuccess = "subscribe_pairing_topic_success"
    case pairingHasPendingRequest = "pairing_has_pending_request"
    case emitSessionProposal = "emit_session_proposal"

    public var description: String {
        return self.rawValue
    }
}

// Enum for TraceErrorEvents
public enum PairingTraceErrorEvents: String, ErrorEvent {
    case noInternetConnection = "no_internet_connection"
    case malformedPairingUri = "malformed_pairing_uri"
    case subscribePairingTopicFailure = "subscribe_pairing_topic_failure"
    case pairingExpired = "pairing_expired"
    case proposalExpired = "proposal_expired"

    public var description: String {
        return self.rawValue
    }
}
