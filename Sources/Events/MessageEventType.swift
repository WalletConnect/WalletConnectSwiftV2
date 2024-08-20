
import Foundation

public enum MessageEventType {
    case sessionAuthenticateLinkMode(RPCID)
    case sessionAuthenticateLinkModeResponseApprove(RPCID)
    case sessionAuthenticateLinkModeResponseReject(RPCID)
    case sessionRequestLinkMode(RPCID)
    case sessionRequestLinkModeResponse(RPCID)

    var tag: Int {
        switch self {
        case .sessionAuthenticateLinkMode:
            return 1122
        case .sessionAuthenticateLinkModeResponseApprove:
            return 1123
        case .sessionAuthenticateLinkModeResponseReject:
            return 1124
        case .sessionRequestLinkMode:
            return 1125
        case .sessionRequestLinkModeResponse:
            return 1126
        }
    }

    func toMessageEventProperties() -> MessageEventProperties {
        switch self {
        case let .sessionAuthenticateLinkMode(rpcId),
             let .sessionAuthenticateLinkModeResponseApprove(rpcId),
             let .sessionAuthenticateLinkModeResponseReject(rpcId),
             let .sessionRequestLinkMode(rpcId),
             let .sessionRequestLinkModeResponse(rpcId):
            return MessageEventProperties(tag: self.tag, rpcId: rpcId)
        }
    }
}
