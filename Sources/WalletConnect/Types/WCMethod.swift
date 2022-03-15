enum WCMethod {
    case wcPairingPing
    case wcSessionPropose(SessionType.ProposeParams)
    case wcSessionSettle(SessionType.SettleParams)
    case wcSessionUpdate(SessionType.UpdateParams)
    case wcSessionUpgrade(SessionType.UpgradeParams)
    case wcSessionDelete(SessionType.DeleteParams)
    case wcSessionRequest(SessionType.RequestParams)
    case wcSessionPing
    case wcSessionExtend(SessionType.ExtendParams)
    case wcSessionNotification(SessionType.NotificationParams)
    
    func asRequest() -> WCRequest {
        switch self {
        case .wcPairingPing:
            return WCRequest(method: .pairingPing, params: .pairingPing(PairingType.PingParams()))
        case .wcSessionPropose(let proposalParams):
            return WCRequest(method: .sessionPropose, params: .sessionPropose(proposalParams))
        case .wcSessionSettle(let settleParams):
            return WCRequest(method: .sessionSettle, params: .sessionSettle(settleParams))
        case .wcSessionUpdate(let updateParams):
            return WCRequest(method: .sessionUpdate, params: .sessionUpdate(updateParams))
        case .wcSessionUpgrade(let upgradeParams):
            return WCRequest(method: .sessionUpgrade, params: .sessionUpgrade(upgradeParams))
        case .wcSessionDelete(let deleteParams):
            return WCRequest(method: .sessionDelete, params: .sessionDelete(deleteParams))
        case .wcSessionRequest(let payloadParams):
            return WCRequest(method: .sessionRequest, params: .sessionRequest(payloadParams))
        case .wcSessionPing:
            return WCRequest(method: .sessionPing, params: .sessionPing(SessionType.PingParams()))
        case .wcSessionNotification(let notificationParams):
            return WCRequest(method: .sessionNotification, params: .sessionNotification(notificationParams))
        case .wcSessionExtend(let extendParams):
            return WCRequest(method: .sessionExtend, params: .sessionExtend(extendParams))
        }
    }
}
