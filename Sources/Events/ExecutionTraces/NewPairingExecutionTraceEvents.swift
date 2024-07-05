
import Foundation

public enum NewPairingExecutionTraceEvents: String, TraceEvent {
    case pairingStarted = "pairing_started"
    case pairingUriValidationSuccess = "pairing_uri_validation_success"
    case pairingUriNotExpired = "pairing_uri_not_expired"
    case storeNewPairing = "store_new_pairing"
    case subscribingPairingTopic = "subscribing_pairing_topic"
    case subscribePairingTopicSuccess = "subscribe_pairing_topic_success"

    public var description: String {
        return self.rawValue
    }
}

// Enum for TraceErrorEvents
public enum TraceErrorEvents: String, ErrorEvent {
    case noWssConnection = "no_wss_connection"
    case noInternetConnection = "no_internet_connection"
    case malformedPairingUri = "malformed_pairing_uri"
    case activePairingAlreadyExists = "active_pairing_already_exists"
    case subscribePairingTopicFailure = "subscribe_pairing_topic_failure"
    case pairingExpired = "pairing_expired"
    case proposalExpired = "proposal_expired"

    public var description: String {
        return self.rawValue
    }
}
