
import Foundation

public enum MessageEventType {
    case sessionAuthenticateLinkModeSent(RPCID)
    case sessionAuthenticateLinkModeReceived(RPCID)
    case sessionAuthenticateLinkModeResponseApproveSent(RPCID)
    case sessionAuthenticateLinkModeResponseApproveReceived(RPCID)
    case sessionAuthenticateLinkModeResponseRejectSent(RPCID)
    case sessionAuthenticateLinkModeResponseRejectReceived(RPCID)
    case sessionRequestLinkModeSent(RPCID)
    case sessionRequestLinkModeReceived(RPCID)
    case sessionRequestLinkModeResponseSent(RPCID)
    case sessionRequestLinkModeResponseReceived(RPCID)

    var rpcId: RPCID {
        switch self {
        case .sessionAuthenticateLinkModeSent(let rpcId),
             .sessionAuthenticateLinkModeReceived(let rpcId),
             .sessionAuthenticateLinkModeResponseApproveSent(let rpcId),
             .sessionAuthenticateLinkModeResponseApproveReceived(let rpcId),
             .sessionAuthenticateLinkModeResponseRejectSent(let rpcId),
             .sessionAuthenticateLinkModeResponseRejectReceived(let rpcId),
             .sessionRequestLinkModeSent(let rpcId),
             .sessionRequestLinkModeReceived(let rpcId),
             .sessionRequestLinkModeResponseSent(let rpcId),
             .sessionRequestLinkModeResponseReceived(let rpcId):
            return rpcId
        }
    }

    var tag: Int {
        switch self {
        case .sessionAuthenticateLinkModeSent, .sessionAuthenticateLinkModeReceived:
            return 1122
        case .sessionAuthenticateLinkModeResponseApproveSent, .sessionAuthenticateLinkModeResponseApproveReceived:
            return 1123
        case .sessionAuthenticateLinkModeResponseRejectSent, .sessionAuthenticateLinkModeResponseRejectReceived:
            return 1124
        case .sessionRequestLinkModeSent, .sessionRequestLinkModeReceived:
            return 1125
        case .sessionRequestLinkModeResponseSent, .sessionRequestLinkModeResponseReceived:
            return 1126
        }
    }

    var direction: MessageEvent.Direction {
        switch self {
        case .sessionAuthenticateLinkModeSent,
             .sessionAuthenticateLinkModeResponseApproveSent,
             .sessionAuthenticateLinkModeResponseRejectSent,
             .sessionRequestLinkModeSent,
             .sessionRequestLinkModeResponseSent:
            return .sent
        case .sessionAuthenticateLinkModeReceived,
             .sessionAuthenticateLinkModeResponseApproveReceived,
             .sessionAuthenticateLinkModeResponseRejectReceived,
             .sessionRequestLinkModeReceived,
             .sessionRequestLinkModeResponseReceived:
            return .received
        }
    }
}
