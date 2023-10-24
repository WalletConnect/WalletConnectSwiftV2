import Foundation

final class SessionExtendRequester {
    private let sessionStore: WCSessionStorage
    private let networkingInteractor: NetworkInteracting

    init(
        sessionStore: WCSessionStorage,
        networkingInteractor: NetworkInteracting
    ) {
        self.sessionStore = sessionStore
        self.networkingInteractor = networkingInteractor
    }

    func extend(topic: String, by ttl: Int64) async throws {
        guard var session = sessionStore.getSession(forTopic: topic) else {
            throw WalletConnectError.noSessionMatchingTopic(topic)
        }
        
        let protocolMethod = SessionExtendProtocolMethod()
        try session.updateExpiry(by: ttl)
        let newExpiry = Int64(session.expiryDate.timeIntervalSince1970)
        sessionStore.setSession(session)
        let request = RPCRequest(method: protocolMethod.method, params: SessionType.UpdateExpiryParams(expiry: newExpiry))
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
    }
}
