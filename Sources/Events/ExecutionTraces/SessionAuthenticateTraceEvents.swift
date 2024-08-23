
import Foundation

public enum SessionAuthenticateTraceEvents: String, TraceEventItem {
    case signatureVerificationStarted = "signature_verification_started"
    case signatureVerificationSuccess = "signature_verification_success"
    case requestParamsRetrieved = "request_params_retrieved"
    case agreementKeysGenerated = "agreement_keys_generated"
    case agreementSecretSet = "agreement_secret_set"
    case sessionKeysGenerated = "session_keys_generated"
    case sessionSecretSet = "session_secret_set"
    case responseParamsCreated = "response_params_created"
    case responseSent = "response_sent"

    public var description: String {
        return self.rawValue
    }
}

public enum SessionAuthenticateErrorEvents: String, ErrorEvent {
    case signatureVerificationFailed = "signature_verification_failed"
    case requestParamsRetrievalFailed = "request_params_retrieval_failed"
    case agreementKeysGenerationFailed = "agreement_keys_generation_failed"
    case agreementSecretSetFailed = "agreement_secret_set_failed"
    case sessionKeysGenerationFailed = "session_keys_generation_failed"
    case sessionSecretSetFailed = "session_secret_set_failed"
    case sessionCreationFailed = "session_creation_failed"
    case responseSendFailed = "response_send_failed"

    public var description: String {
        return self.rawValue
    }
}
