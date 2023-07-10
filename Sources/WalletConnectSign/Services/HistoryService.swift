import Foundation

final class HistoryService {

    private let history: RPCHistory
    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private let verifyContextStore: CodableStore<VerifyContext>

    init(
        history: RPCHistory,
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        verifyContextStore: CodableStore<VerifyContext>
    ) {
        self.history = history
        self.proposalPayloadsStore = proposalPayloadsStore
        self.verifyContextStore = verifyContextStore
    }

    public func getSessionRequest(id: RPCID) -> (request: Request, context: VerifyContext?)? {
        guard let record = history.get(recordId: id) else { return nil }
        guard let request = mapRequestRecord(record) else {
            return nil
        }
        return (request, try? verifyContextStore.get(key: request.id.string))
    }
    
    func getPendingRequests() -> [(request: Request, context: VerifyContext?)] {
        let requests = history.getPending()
            .compactMap { mapRequestRecord($0) }
            .filter { !$0.isExpired() }
        return requests.map { ($0, try? verifyContextStore.get(key: $0.id.string)) }
    }

    func getPendingRequests(topic: String) -> [(request: Request, context: VerifyContext?)] {
        return getPendingRequests().filter { $0.request.topic == topic }
    }
    
    func getPendingProposals() -> [(proposal: Session.Proposal, context: VerifyContext?)] {
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
        
        let proposals = pendingHistory
            .compactMap { mapProposalRecord($0) }
        
        return proposals.map { ($0, try? verifyContextStore.get(key: $0.proposal.proposer.publicKey)) }
    }
    
    func getPendingProposals(topic: String) -> [(proposal: Session.Proposal, context: VerifyContext?)] {
        return getPendingProposals().filter { $0.proposal.pairingTopic == topic }
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
