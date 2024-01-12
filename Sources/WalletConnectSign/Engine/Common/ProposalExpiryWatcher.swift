import Foundation
import Combine

class ProposalExpiryWatcher {

    private let sessionProposalExpirationPublisherSubject: PassthroughSubject<Session.Proposal, Never> = .init()
    private let rpcHistory: RPCHistory

    var sessionProposalExpirationPublisher: AnyPublisher<Session.Proposal, Never> {
        return sessionProposalExpirationPublisherSubject.eraseToAnyPublisher()
    }

    private let proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>
    private var checkTimer: Timer?

    internal init(
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        rpcHistory: RPCHistory
    ) {
        self.proposalPayloadsStore = proposalPayloadsStore
        self.rpcHistory = rpcHistory
        setUpExpiryCheckTimer()
    }

    func setUpExpiryCheckTimer() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [unowned self] _ in
            checkForProposalsExpiry()
        }
    }

    func checkForProposalsExpiry() {
        let proposals = proposalPayloadsStore.getAll()
        proposals.forEach { proposalPayload in
            let pairingTopic = proposalPayload.topic
            guard proposalPayload.request.isExpired() else { return }
            sessionProposalExpirationPublisherSubject.send(proposalPayload.request.publicRepresentation(pairingTopic: pairingTopic))
            proposalPayloadsStore.delete(forKey: proposalPayload.request.proposer.publicKey)
            rpcHistory.delete(id: proposalPayload.id)
        }
    }
}
