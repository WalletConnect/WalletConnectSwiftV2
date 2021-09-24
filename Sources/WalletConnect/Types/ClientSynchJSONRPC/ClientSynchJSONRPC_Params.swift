
import Foundation

extension ClientSynchJSONRPC {
    enum Params: Codable, Equatable {
        case pairingApprove(PairingType.ApproveParams)
        case pairingReject(PairingType.RejectParams)
        case pairingUpdate(PairingType.UpdateParams)
        case pairingUpgrade(PairingType.UpgradeParams)
        case pairingDelete(PairingType.DeleteParams)
        case pairingPayload(PairingType.PayloadParams)
        // sessionPropose method exists exclusively within a pairing payload
        case sessionPropose(SessionType.ProposeParams)
        case sessionApprove(SessionType.ApproveParams)
        case sessionReject(SessionType.RejectParams)
        case sessionUpdate(SessionType.UpdateParams)
        case sessionUpgrade(SessionType.UpgradeParams)
        case sessionDelete(SessionType.DeleteParams)
        case sessionPayload(SessionType.PayloadParams)

        static func == (lhs: Params, rhs: Params) -> Bool {
            switch (lhs, rhs) {
            case (.pairingApprove(let lhsParam), .pairingApprove(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingReject(let lhsParam), pairingReject(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingUpdate(let lhsParam), pairingUpdate(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingUpgrade(let lhsParam), pairingUpgrade(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingDelete(let lhsParam), pairingDelete(let rhsParam)):
                return lhsParam == rhsParam
            case (.pairingPayload(let lhsParam), pairingPayload(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionPropose(let lhsParam), sessionPropose(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionApprove(let lhsParam), sessionApprove(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionReject(let lhsParam), sessionReject(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionUpdate(let lhsParam), sessionUpdate(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionUpgrade(let lhsParam), sessionUpgrade(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionDelete(let lhsParam), sessionDelete(let rhsParam)):
                return lhsParam == rhsParam
            case (.sessionPayload(let lhsParam), sessionPayload(let rhsParam)):
                return lhsParam == rhsParam
            default:
                return false
            }
        }
        
        init(from decoder: Decoder) throws {
            fatalError("forbidden")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("forbidden")
        }
    }
}
