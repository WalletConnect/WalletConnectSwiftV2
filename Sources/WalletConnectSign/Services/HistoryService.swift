import Foundation

final class HistoryService {

    private let history: RPCHistory
    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>

    init(
        history: RPCHistory,
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    ) {
        self.history = history
        self.proposalPayloadsStore = proposalPayloadsStore
    }

    public func getSessionRequest(id: RPCID) -> Request? {
        guard let record = history.get(recordId: id) else { return nil }
        return mapRequestRecord(record)
    }
    
    func getPendingRequests() -> [Request] {
        return history.getPending()
            .compactMap { mapRequestRecord($0) }
            .filter { !$0.isExpired() }
    }

    func getPendingRequests(topic: String) -> [Request] {
        return getPendingRequests().filter { $0.topic == topic }
    }
    
    func getPendingProposals() -> [Session.Proposal] {
        let pendingHistory = history.getPending()
        
        let requestSubscriptionPayloads = pendingHistory
            .compactMap { record -> RequestSubscriptionPayload<SessionType.ProposeParams>? in
                guard let proposalParams = mapProposeParams(record) else {
                    return nil
                }
                return RequestSubscriptionPayload(id: record.id, topic: record.topic, request: proposalParams, decryptedPayload: Data(), publishedAt: Date(), derivedTopic: nil)
            }
        
        requestSubscriptionPayloads.forEach {
            let proposal = $0.request
            proposalPayloadsStore.set($0, forKey: proposal.proposer.publicKey)
        }
        
        return pendingHistory
            .compactMap { mapProposalRecord($0) }
    }
    
    func getPendingProposals(topic: String) -> [Session.Proposal] {
        return getPendingProposals().filter { $0.pairingTopic == topic }
    }
}

private extension HistoryService {
    func mapRequestRecord(_ record: RPCHistory.Record) -> Request? {
        guard let request = try? record.request.params?.get(SessionType.RequestParams.self)
        else { return nil }

        return Request(
            id: record.id,
            topic: record.topic,
            method: request.request.method,
            params: request.request.params,
            chainId: request.chainId,
            expiry: request.request.expiry
        )
    }
    
    func mapProposeParams(_ record: RPCHistory.Record) -> SessionType.ProposeParams? {
        guard let proposal = try? record.request.params?.get(SessionType.ProposeParams.self)
        else { return nil }
        return proposal
    }
    
    func mapProposalRecord(_ record: RPCHistory.Record) -> Session.Proposal? {
        guard let proposal = try? record.request.params?.get(SessionType.ProposeParams.self)
        else { return nil }
        
        return Session.Proposal(
            id: proposal.proposer.publicKey,
            pairingTopic: record.topic,
            proposer: proposal.proposer.metadata,
            requiredNamespaces: proposal.requiredNamespaces,
            optionalNamespaces: proposal.optionalNamespaces,
            sessionProperties: proposal.sessionProperties,
            proposal: proposal
        )
    }
}
