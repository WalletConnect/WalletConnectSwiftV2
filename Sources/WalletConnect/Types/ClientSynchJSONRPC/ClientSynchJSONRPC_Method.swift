
import Foundation

extension ClientSynchJSONRPC {
    enum Method: String, Codable {
        case pairingApprove = "wc_pairingApprove"
        case pairingReject = "wc_pairingReject"
        case pairingUpdate = "wc_pairingUpdate"
        case pairingUpgrade = "wc_pairingUpgrade"
        case pairingDelete = "wc_pairingDelete"
        case pairingPayload = "wc_pairingPayload"
        case sessionPropose = "wc_sessionPropose"
        case sessionApprove = "wc_sessionApprove"
        case sessionReject = "wc_sessionReject"
        case sessionUpdate = "wc_sessionUpdate"
        case sessionUpgrade = "wc_sessionUpgrade"
        case sessionDelete = "wc_sessionDelete"
        case sessionPayload = "wc_sessionPayload"
    }
}
