enum WCMethod {
    case wcPairingPing
    case wcSessionPropose(SessionType.ProposeParams)
    case wcSessionSettle(SessionType.SettleParams)
    case wcSessionUpdateAccounts(SessionType.UpdateAccountsParams)
    case wcSessionUpdateNamespaces(SessionType.UpdateNamespaceParams)
    case wcSessionUpdateExpiry(SessionType.UpdateExpiryParams)
    case wcSessionDelete(SessionType.DeleteParams)
    case wcSessionRequest(SessionType.RequestParams)
    case wcSessionPing
    case wcSessionEvent(SessionType.EventParams)
    
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
        case .wcSessionUpdateNamespaces(let updateParams):
            return WCRequest(method: .sessionUpdateNamespaces, params: .sessionUpdateNamespaces(updateParams))
        case .wcSessionUpdateExpiry(let updateExpiryParams):
            return WCRequest(method: .sessionUpdateExpiry, params: .sessionUpdateExpiry(updateExpiryParams))
        case .wcSessionDelete(let deleteParams):
            return WCRequest(method: .sessionDelete, params: .sessionDelete(deleteParams))
        case .wcSessionRequest(let payloadParams):
            return WCRequest(method: .sessionRequest, params: .sessionRequest(payloadParams))
        case .wcSessionPing:
            return WCRequest(method: .sessionPing, params: .sessionPing(SessionType.PingParams()))
        case .wcSessionEvent(let eventParams):
            return WCRequest(method: .sessionEvent, params: .sessionEvent(eventParams))
        }
    }
}
