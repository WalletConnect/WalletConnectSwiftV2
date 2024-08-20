
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

    var direction: Direction {
        switch self {
        case .sessionAuthenticateLinkModeSent, .sessionAuthenticateLinkModeResponseApproveSent, .sessionAuthenticateLinkModeResponseRejectSent, .sessionRequestLinkModeSent, .sessionRequestLinkModeResponseSent:
            return .send
        case .sessionAuthenticateLinkModeReceived, .sessionAuthenticateLinkModeResponseApproveReceived, .sessionAuthenticateLinkModeResponseRejectReceived, .sessionRequestLinkModeReceived, .sessionRequestLinkModeResponseReceived:
            return .received
        }
    }

    func toMessageEventProperties() -> MessageEventProperties {
        switch self {
        case let .sessionAuthenticateLinkModeSent(rpcId),
             let .sessionAuthenticateLinkModeReceived(rpcId),
             let .sessionAuthenticateLinkModeResponseApproveSent(rpcId),
             let .sessionAuthenticateLinkModeResponseApproveReceived(rpcId),
             let .sessionAuthenticateLinkModeResponseRejectSent(rpcId),
             let .sessionAuthenticateLinkModeResponseRejectReceived(rpcId),
             let .sessionRequestLinkModeSent(rpcId),
             let .sessionRequestLinkModeReceived(rpcId),
             let .sessionRequestLinkModeResponseSent(rpcId),
             let .sessionRequestLinkModeResponseReceived(rpcId):
            return MessageEventProperties(tag: self.tag, rpcId: rpcId, direction: self.direction)
        }
    }
}
