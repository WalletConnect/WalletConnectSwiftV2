enum WCMethod {
    case wcPairingPing
    case wcSessionPropose(SessionType.ProposeParams)
    case wcSessionSettle(SessionType.SettleParams)
    case wcSessionUpdateAccounts(SessionType.UpdateAccountsParams)
    case wcSessionDelete(SessionType.DeleteParams)
    case wcSessionRequest(SessionType.RequestParams)
    case wcSessionPing
    case wcSessionExtend(SessionType.UpdateExpiryParams)
    case wcSessionNotification(SessionType.EventParams)
    
    func asRequest() -> WCRequest {
        switch self {
        case .wcPairingPing:
            return WCRequest(method: .pairingPing, params: .pairingPing(PairingType.PingParams()))
        case .wcSessionPropose(let proposalParams):
            return WCRequest(method: .sessionPropose, params: .sessionPropose(proposalParams))
        case .wcSessionSettle(let settleParams):
            return WCRequest(method: .sessionSettle, params: .sessionSettle(settleParams))
        case .wcSessionUpdateAccounts(let updateParams):
            return WCRequest(method: .sessionUpdateAccounts, params: .sessionUpdateAccounts(updateParams))
        case .wcSessionDelete(let deleteParams):
            return WCRequest(method: .sessionDelete, params: .sessionDelete(deleteParams))
        case .wcSessionRequest(let payloadParams):
            return WCRequest(method: .sessionRequest, params: .sessionRequest(payloadParams))
        case .wcSessionPing:
            return WCRequest(method: .sessionPing, params: .sessionPing(SessionType.PingParams()))
        case .wcSessionNotification(let notificationParams):
            return WCRequest(method: .sessionEvent, params: .sessionEvent(notificationParams))
        case .wcSessionExtend(let extendParams):
            return WCRequest(method: .sessionUpdateExpiry, params: .sessionUpdateExpiry(extendParams))
        }
    }
}
